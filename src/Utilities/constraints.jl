"""
    add_scalar_constraint(model::MOI.ModelLike,
                          func::MOI.AbstractScalarFunction,
                          set::MOI.AbstractScalarSet;
                          allow_modify_function::Bool=false)

Adds the scalar constraint obtained by moving the constant term in `func` to
the set in `model`. If `allow_modify_function` is `true` then the function
`func`, can be modified.
"""
function add_scalar_constraint end

function add_scalar_constraint(model::MOI.ModelLike, func::MOI.SingleVariable,
                               set::MOI.AbstractScalarSet;
                               allow_modify_function::Bool=false)
    # TODO pass allow_modify_function in MOI v0.7
    return MOI.add_constraint(model, func, set)
end
function add_scalar_constraint(model::MOI.ModelLike,
                               func::Union{MOI.ScalarAffineFunction{T},
                                           MOI.ScalarQuadraticFunction{T}},
                               set::MOI.AbstractScalarSet;
                               allow_modify_function::Bool=false) where T
    set = shift_constant(set, -func.constant)
    if !allow_modify_function
        func = copy(func)
    end
    func.constant = zero(T)
    # TODO pass allow_modify_function in MOI v0.7
    return MOI.add_constraint(model, func, set)
end
