"""
    VectorizeBridge{T, F, S, G}

Transforms a constraint `G`-in-`scalar_set_type(S, T)` where
`S <: VectorLinearSet` to `F`-in-`S`.

## Examples

The constraint `SingleVariable -in- LessThan{Float64}` becomes
`VectorAffineFunction{Float64} -in- Nonpositives`, where `T = Float64`,
`F = VectorAffineFunction{Float64}`, `S = Nonpositives`, and
`G = SingleVariable`.
"""
mutable struct VectorizeBridge{T, F, S, G} <: AbstractBridge
    vector_constraint::CI{F, S}
    set_constant::T # constant in scalar set
end

function bridge_constraint(
    ::Type{VectorizeBridge{T, F, S, G}},
    model::MOI.ModelLike,
    g::G,
    set::MOIU.ScalarLinearSet{T}
) where {T, F, S, G}
    g_const = MOI.constant(g, T)
    if !iszero(g_const)
        throw(
            MOI.ScalarFunctionConstantNotZero{
                typeof(g_const), G, typeof(set)
            }(g_const)
        )
    end
    vaf = _vectorized_convert(F, g)
    set_const = MOI.constant(set)
    MOIU.operate_output_index!(-, T, 1, vaf, set_const)
    vector_constraint = MOI.add_constraint(model, vaf, S(1))
    return VectorizeBridge{T, F, S, G}(vector_constraint, set_const)
end

function _vectorized_convert(
    ::Type{MOI.VectorOfVariables}, g::MOI.SingleVariable
)
    return MOI.VectorOfVariables([g.variable])
end

function _vectorized_convert(
    ::Type{MOI.VectorAffineFunction{T}}, g::MOI.SingleVariable
) where {T}
    return MOI.VectorAffineFunction{T}(
        [MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, g.variable))],
        [zero(T)]
    )
end

function _vectorized_convert(
    ::Type{MOI.VectorQuadraticFunction{T}}, g::MOI.SingleVariable
) where {T}
    return MOI.VectorQuadraticFunction{T}(
        [MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, g.variable))],
        MOI.VectorQuadraticTerm{T}[],
        [zero(T)]
    )
end

function _vectorized_convert(
    ::Type{MOI.VectorAffineFunction{T}}, g::MOI.ScalarAffineFunction
) where {T}
    return MOI.VectorAffineFunction{T}(
        MOI.VectorAffineTerm{T}[
            MOI.VectorAffineTerm(1, term) for term in g.terms
        ],
        [g.constant]
    )
end

function _vectorized_convert(
    ::Type{MOI.VectorQuadraticFunction{T}}, g::MOI.ScalarAffineFunction
) where {T}
    return MOI.VectorQuadraticFunction{T}(
        MOI.VectorAffineTerm{T}[
            MOI.VectorAffineTerm(1, term) for term in g.terms
        ],
        MOI.VectorQuadraticTerm{T}[],
        [g.constant]
    )
end

function _vectorized_convert(
    ::Type{MOI.VectorQuadraticFunction{T}}, g::MOI.ScalarQuadraticFunction
) where {T}
    return MOI.VectorQuadraticFunction{T}(
        MOI.VectorAffineTerm{T}[
            MOI.VectorAffineTerm(1, term) for term in g.affine_terms
        ],
        MOI.VectorQuadraticTerm{T}[
            MOI.VectorQuadraticTerm(1, term) for term in g.quadratic_terms
        ],
        [g.constant]
    )
end

function MOI.supports_constraint(
    ::Type{VectorizeBridge{T}},
    ::Type{<:MOI.AbstractScalarFunction},
    ::Type{<:MOIU.ScalarLinearSet{T}},
) where {T}
    return true
end

function MOIB.added_constrained_variable_types(::Type{<:VectorizeBridge})
    return Tuple{DataType}[]
end

function MOIB.added_constraint_types(
    ::Type{<:VectorizeBridge{T, F, S}}
) where {T, F, S}
    return [(F, S)]
end

function concrete_bridge_type(
    ::Type{<:VectorizeBridge{T}},
    G::Type{<:MOI.AbstractScalarFunction},
    S::Type{<:MOIU.ScalarLinearSet{T}},
) where {T}
    H = MOIU.promote_operation(-, T, G, T)
    F = MOIU.promote_operation(vcat, T, H)
    return VectorizeBridge{T, F, MOIU.vector_set_type(S), G}
end

# Attributes, Bridge acting as a model

function MOI.get(
    ::VectorizeBridge{T, F, S}, ::MOI.NumberOfConstraints{F, S}
) where {T, F, S}
    return 1
end

function MOI.get(
    bridge::VectorizeBridge{T, F, S}, ::MOI.ListOfConstraintIndices{F, S}
) where {T, F, S}
    return [bridge.vector_constraint]
end

function MOI.delete(model::MOI.ModelLike, bridge::VectorizeBridge)
    MOI.delete(model, bridge.vector_constraint)
end

# Attributes, Bridge acting as a constraint

function MOI.supports(
    ::MOI.ModelLike,
    ::Union{MOI.ConstraintPrimalStart, MOI.ConstraintDualStart},
    ::Type{<:VectorizeBridge},
)
    return true
end

function MOI.get(
    model::MOI.ModelLike,
    attr::MOI.ConstraintPrimalStart,
    bridge::VectorizeBridge,
)
    x = MOI.get(model, attr, bridge.vector_constraint)
    @assert length(x) == 1
    return x[1] + bridge.set_constant
end

function MOI.get(
    model::MOI.ModelLike,
    attr::MOI.ConstraintPrimal,
    bridge::VectorizeBridge,
)
    x = MOI.get(model, attr, bridge.vector_constraint)
    @assert length(x) == 1
    if MOIU.is_ray(MOI.get(model, MOI.PrimalStatus(attr.N)))
       # If it is an infeasibility certificate, it is a ray and satisfies the
       # homogenized problem, see https://github.com/JuliaOpt/MathOptInterface.jl/issues/433
       return x[1]
    else
       # Otherwise, we need to add the set constant since the ConstraintPrimal
       # is defined as the value of the function and the set_constant was
       # removed from the original function
       return x[1] + bridge.set_constant
    end
end

function MOI.set(
    model::MOI.ModelLike,
    attr::MOI.ConstraintPrimalStart,
    bridge::VectorizeBridge,
    value,
)
    MOI.set(
        model, attr, bridge.vector_constraint, [value - bridge.set_constant]
    )
    return
end

function MOI.get(
    model::MOI.ModelLike,
    attr::Union{MOI.ConstraintDual, MOI.ConstraintDualStart},
    bridge::VectorizeBridge,
)
    x = MOI.get(model, attr, bridge.vector_constraint)
    @assert length(x) == 1
    return x[1]
end

function MOI.set(
    model::MOI.ModelLike,
    attr::MOI.ConstraintDualStart,
    bridge::VectorizeBridge,
    value,
)
    MOI.set(model, attr, bridge.vector_constraint, [value])
    return
end

function MOI.modify(
    model::MOI.ModelLike,
    bridge::VectorizeBridge,
    change::MOI.ScalarCoefficientChange,
)
    MOI.modify(
        model,
        bridge.vector_constraint,
        MOI.MultirowChange(change.variable, [(1, change.new_coefficient)]),
    )
    return
end

function MOI.set(
    model::MOI.ModelLike,
    ::MOI.ConstraintSet,
    bridge::VectorizeBridge,
    new_set::MOIU.ScalarLinearSet,
)
    bridge.set_constant = MOI.constant(new_set)
    MOI.modify(
        model,
        bridge.vector_constraint,
        MOI.VectorConstantChange([-bridge.set_constant]),
    )
    return
end

function MOI.get(
    model::MOI.ModelLike,
    attr::MOI.ConstraintFunction,
    bridge::VectorizeBridge{T, F, S, G}
) where {T, F, S, G}
    f = MOIU.scalarize(MOI.get(model, attr, bridge.vector_constraint), true)
    @assert length(f) == 1
    return convert(G, f[1])
end

function MOI.get(
    model::MOI.ModelLike, ::MOI.ConstraintSet, bridge::VectorizeBridge{T, F, S}
) where {T, F, S}
    return MOIU.scalar_set_type(S, T)(bridge.set_constant)
end
