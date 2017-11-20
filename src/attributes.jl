# Attributes

"""
    AbstractInstanceAttribute

Abstract supertype for attribute objects that can be used to set or get attributes (properties) of the instance.
"""
abstract type AbstractInstanceAttribute end

"""
    AbstractVariableAttribute

Abstract supertype for attribute objects that can be used to set or get attributes (properties) of variables in the instance.
"""
abstract type AbstractVariableAttribute end

"""
    AbstractConstraintAttribute

Abstract supertype for attribute objects that can be used to set or get attributes (properties) of constraints in the instance.
"""
abstract type AbstractConstraintAttribute end

const AnyAttribute = Union{AbstractInstanceAttribute, AbstractVariableAttribute, AbstractConstraintAttribute}

"""
    get(instance::AbstractInstance, attr::AbstractInstanceAttribute)

Return an attribute `attr` of the instance `instance`.

    get(instance::AbstractInstance, attr::AbstractVariableAttribute, v::VariableReference)

Return an attribute `attr` of the variable `v` in instance `instance`.

    get(instance::AbstractInstance, attr::AbstractVariableAttribute, v::Vector{VariableReference})

Return a vector of attributes corresponding to each variable in the collection `v` in the instance `instance`.

    get(instance::AbstractInstance, attr::AbstractConstraintAttribute, c::ConstraintReference)

Return an attribute `attr` of the constraint `c` in instance `instance`.

    get(instance::AbstractInstance, attr::AbstractConstraintAttribute, c::Vector{ConstraintReference{F,S}})

Return a vector of attributes corresponding to each constraint in the collection `c` in the instance `instance`.

    get(instance::AbstractInstance, ::Type{VariableReference}, name::String)

If a variable with name `name` exists in the instance `instance`, return the corresponding reference object, otherwise throw a `KeyError`.

    get(instance::AbstractInstance, ::Type{ConstraintReference{F,S}}, name::String) where {F<:AbstractFunction,S<:AbstractSet}

If an `F`-in-`S` constraint with name `name` exists in the instance `instance`, return the corresponding reference object, otherwise throw a `KeyError`.

    get(instance::AbstractInstance, ::Type{ConstraintReference}, name::String)

If *any* constraint with name `name` exists in the instance `instance`, return the corresponding reference object, otherwise throw a `KeyError`. This version is available for convenience but may incur a performance penalty because it is not type stable.

### Examples

```julia
get(instance, ObjectiveValue())
get(instance, VariablePrimal(), ref)
get(instance, VariablePrimal(5), [ref1, ref2])
get(instance, OtherAttribute("something specific to cplex"))
get(instance, VariableReference, "var1")
get(instance, ConstraintReference{ScalarAffineFunction{Float64},LessThan{Float64}}, "con1")
get(instance, ConstraintReference, "con1")
```
"""
function get end

function get(instance::AbstractInstance, attr::AnyAttribute, args...)
    throw(ArgumentError("AbstractInstance of type $(typeof(instance)) does not support accessing the attribute $attr"))
end

"""
    get!(output, instance::AbstractInstance, args...)

An in-place version of `get`.
The signature matches that of `get` except that the the result is placed in the vector `output`.
"""
function get! end
function get!(output, instance::AbstractInstance, attr::AnyAttribute, args...)
    throw(ArgumentError("AbstractInstance of type $(typeof(instance)) does not support accessing the attribute $attr"))
end

"""
    canget(instance::AbstractInstance, attr::AbstractVariableAttribute, v::VariableReference)::Bool
    canget(instance::AbstractInstance, attr::AbstractConstraintAttribute, c::ConstraintReference{F,S})::Bool

Return a `Bool` indicating whether the instance `instance` currently has a value for the attributed specified by attribute type `attr` applied to the variable reference `v` or constraint reference `c`.

    canget(instance::AbstractInstance, attr::AbstractVariableAttribute, v::Vector{VariableReference})::Bool
    canget(instance::AbstractInstance, attr::AbstractConstraintAttribute, c::Vector{ConstraintReference{F,S}})::Bool

Return a `Bool` indicating whether the instance `instance` currently has a value for the attributed specified by attribute type `attr` applied to *every* variable references in `v` or constraint reference in `c`.

    canget(instance::AbstractInstance, ::Type{VariableReference}, name::String)::Bool

Return a `Bool` indicating if a variable with the name `name` exists in the instance.

    canget(instance::AbstractInstance, ::Type{ConstraintReference{F,S}}, name::String)::Bool where {F<:AbstractFunction,S<:AbstractSet}

Return a `Bool` indicating if an `F`-in-`S` constraint with the name `name` exists in the instance `instance`.

    canget(instance::AbstractInstance, ::Type{ConstraintReference}, name::String)::Bool

Return a `Bool` indicating if a constraint of any kind with the name `name` exists in the instance `instance`.


### Examples

```julia
canget(instance, ObjectiveValue())
canget(instance, VariablePrimalStart(), varref)
canget(instance, ConstraintPrimal(), conref)
canget(instance, VariablePrimal(), [ref1, ref2])
canget(instance, VariableReference, "var1")
canget(instance, ConstraintReference{ScalarAffineFunction{Float64},LessThan{Float64}}, "con1")
canget(instance, ConstraintReference, "con1")
```
"""
function canget end
canget(instance::AbstractInstance, attr::AnyAttribute) = false
canget(instance::AbstractInstance, attr::AnyAttribute, ref::AnyReference) = false
canget(instance::AbstractInstance, attr::AnyAttribute, refs::Vector{<:AnyReference}) = false

"""
    canset(instance::AbstractInstance, attr::AbstractVariableAttribute, R::Type{VariableReference})::Bool
    canget(instance::AbstractInstance, attr::AbstractConstraintAttribute, R::Type{ConstraintReference{F,S})::Bool

Return a `Bool` indicating whether it is possible to set attribute `attr` applied to the reference type `R` in the instance `instance`.

    canset(instance::AbstractInstance, attr::AbstractVariableAttribute, v::Vector{VariableReference})::Bool
    canset(instance::AbstractInstance, attr::AbstractConstraintAttribute, c::Vector{ConstraintReference{F,S}})::Bool

Return a `Bool` indicating whether it is possible to set attribute `attr`applied to *every* variable reference in `v` or constraint reference in `c` in the instance `instance`.

### Examples

```julia
canset(instance, ObjectiveValue())
canset(instance, VariablePrimalStart(), VariableReference)
canset(instance, ConstraintPrimal(), ConstraintReference{VectorAffineFunction{Float64},Nonnegatives})
```
"""
function canset end
canset(instance::AbstractInstance, attr::AnyAttribute) = false
canset(instance::AbstractInstance, attr::AnyAttribute, ref::AnyReference) = false
canset(instance::AbstractInstance, attr::AnyAttribute, refs::Vector{<:AnyReference}) = false

"""
    set!(instance::AbstractInstance, attr::AbstractInstanceAttribute, value)

Assign `value` to the attribute `attr` of the instance `instance`.

    set!(instance::AbstractInstance, attr::AbstractVariableAttribute, v::VariableReference, value)

Assign `value` to the attribute `attr` of variable `v` in instance `instance`.

    set!(instance::AbstractInstance, attr::AbstractVariableAttribute, v::Vector{VariableReference}, vector_of_values)

Assign a value respectively to the attribute `attr` of each variable in the collection `v` in instance `instance`.

    set!(instance::AbstractInstance, attr::AbstractConstraintAttribute, c::ConstraintReference, value)

Assign a value to the attribute `attr` of constraint `c` in instance `instance`.

    set!(instance::AbstractInstance, attr::AbstractConstraintAttribute, c::Vector{ConstraintReference{F,S}})

Assign a value respectively to the attribute `attr` of each constraint in the collection `c` in instance `instance`.
"""
function set! end
function set!(instance::AbstractInstance, attr::AnyAttribute, args...)
    throw(ArgumentError("AbstractInstance of type $(typeof(instance)) does not support setting the attribute $attr"))
end

# TODO: solver-independent parameters

## Instance attributes

"""
    Name()

A string identifying the instance.
"""
struct Name <: AbstractInstanceAttribute end

"""
    ObjectiveSense()

The sense of the objective function, an `OptimizationSense` with value `MinSense`, `MaxSense`, or `FeasiblitySense`.
"""
struct ObjectiveSense <: AbstractInstanceAttribute end

@enum OptimizationSense MinSense MaxSense FeasibilitySense

"""
    NumberOfVariables()

The number of variables in the instance.
"""
struct NumberOfVariables <: AbstractInstanceAttribute end

"""
    ListOfVariableReferences()

A `Vector{VariableReference}` with references to all variables present
in the instance (i.e., of length equal to the value of `NumberOfVariables()`).
"""
struct ListOfVariableReferences <: AbstractInstanceAttribute end

"""
    ListOfConstraintReferences{F,S}()

A `Vector{ConstraintReferences{F,S}}` with references to all constraints of
type `F`-in`S` in the instance (i.e., of length equal to the value of `NumberOfConstraints{F,S}()`).
"""
struct ListOfConstraintReferences{F,S} <: AbstractInstanceAttribute end

"""
    NumberOfConstraints{F,S}()

The number of constraints of the type `F`-in-`S` present in the instance.
"""
struct NumberOfConstraints{F,S} <: AbstractInstanceAttribute end

"""
    ListOfConstraints()

A list of tuples of the form `(F,S)`, where `F` is a function type
and `S` is a set type indicating that the attribute `NumberOfConstraints{F,S}()`
has value greater than zero.
"""
struct ListOfConstraints <: AbstractInstanceAttribute end

"""
    ObjectiveFunction()

An `AbstractFunction` instance which represents the objective function.
It is guaranteed to be equivalent but not necessarily identical to the function provided by the user.
"""
struct ObjectiveFunction <: AbstractInstanceAttribute end

## Solver instance attributes

"""
    ObjectiveValue(resultidx::Int=1)

The objective value of the `resultindex`th primal result.
"""
struct ObjectiveValue <: AbstractInstanceAttribute
    resultindex::Int
    (::Type{ObjectiveValue})(resultindex=1) = new(resultindex)
end

"""
    ObjectiveBound()

The best known bound on the optimal objective value.
"""
struct ObjectiveBound <: AbstractInstanceAttribute end

"""
    RelativeGap()

The final relative optimality gap, defined as ``\\frac{|b-f|}{|f|}``, where ``b`` is the best bound and ``f`` is the best feasible objective value.
"""
struct RelativeGap <: AbstractInstanceAttribute  end

"""
    SolveTime()

The total elapsed solution time (in seconds) as reported by the solver.
"""
struct SolveTime <: AbstractInstanceAttribute end

"""
    SimplexIterations()

The cumulative number of simplex iterations during the optimization process.
In particular, for a mixed-integer program (MIP), the total simplex iterations for all nodes.
"""
struct SimplexIterations <: AbstractInstanceAttribute end

"""
    BarrierIterations()

The cumulative number of barrier iterations while solving a problem.
"""
struct BarrierIterations <: AbstractInstanceAttribute end

"""
    NodeCount()

The total number of branch-and-bound nodes explored while solving a mixed-integer program (MIP).
"""
struct NodeCount <: AbstractInstanceAttribute end

"""
    RawSolver()

An object that may be used to access a solver-specific API for this solver instance.
"""
struct RawSolver <: AbstractInstanceAttribute end

"""
    ResultCount()

The number of results available.
"""
struct ResultCount <: AbstractInstanceAttribute end

## Variable attributes

"""
    VariableName()

A string identifying the variable. It is invalid for two variables to have the same name.
"""
struct VariableName <: AbstractVariableAttribute end

"""
    VariablePrimalStart()

An initial assignment of the variables that the solver may use to warm-start the solve.
"""
struct VariablePrimalStart <: AbstractVariableAttribute end

"""
    VariablePrimal(N)
    VariablePrimal()

The assignment to the primal variables in result `N`.
If `N` is omitted, it is 1 by default.
"""
struct VariablePrimal <: AbstractVariableAttribute
    N::Int
end
VariablePrimal() = VariablePrimal(1)

"""
    VariableBasisStatus()

Returns the `BasisStatusCode` of a given variable, with respect to an available optimal solution basis.
"""
struct VariableBasisStatus <: AbstractVariableAttribute end

"""
    BasisStatusCode

An Enum of possible values for the `VariableBasisStatus` and `ConstraintBasisStatus` attribute.
This explains the status of a given element with respect to an optimal solution basis.
Possible values are:
* `Basic`: element is in the basis
* `Nonbasic`: element is not in the basis
* `NonbasicAtLower`: element is not in the basis and is at its lower bound
* `NonbasicAtUpper`: element is not in the basis and is at its upper bound
* `SuperBasic`: element is not in the basis but is also not at one of its bounds
"""
@enum BasisStatusCode Basic Nonbasic NonbasicAtLower NonbasicAtUpper SuperBasic

## Constraint attributes

"""
    ConstraintName()

A string identifying the constraint. It is invalid for two constraints of any kind to have the same name.
"""
struct ConstraintName <: AbstractConstraintAttribute end

"""
    ConstraintPrimalStart()

An initial assignment of the constraint primal values that the solver may use to warm-start the solve.
"""
struct ConstraintPrimalStart <: AbstractConstraintAttribute end

"""
    ConstraintDualStart()

An initial assignment of the constraint duals that the solver may use to warm-start the solve.
"""
struct ConstraintDualStart <: AbstractConstraintAttribute end

"""
    ConstraintPrimal(N)
    ConstraintPrimal()

The assignment to the constraint primal values in result `N`.
If `N` is omitted, it is 1 by default.
"""
struct ConstraintPrimal <: AbstractConstraintAttribute
    N::Int
end
ConstraintPrimal() = ConstraintPrimal(1)

"""
    ConstraintDual(N)
    ConstraintDual()

The assignment to the constraint dual values in result `N`.
If `N` is omitted, it is 1 by default.
"""
struct ConstraintDual <: AbstractConstraintAttribute
    N::Int
end
ConstraintDual() = ConstraintDual(1)

"""
    ConstraintBasisStatus()

Returns the `BasisStatusCode` of a given constraint, with respect to an available optimal solution basis.
"""
struct ConstraintBasisStatus <: AbstractConstraintAttribute end

"""
    ConstraintFunction()

Return the `AbstractFunction` object used to define the constraint.
It is guaranteed to be equivalent but not necessarily identical to the function provided by the user.
"""
struct ConstraintFunction <: AbstractConstraintAttribute end

"""
    ConstraintSet()

Return the `AbstractSet` object used to define the constraint.
"""
struct ConstraintSet <: AbstractConstraintAttribute end

## Termination status
"""
    TerminationStatus()

A `TerminationStatusCode` explaining why the solver stopped.
"""
struct TerminationStatus <: AbstractInstanceAttribute end

"""
    TerminationStatusCode

An Enum of possible values for the `TerminationStatus` attribute.
This attribute is meant to explain the reason why the solver stopped executing.

## OK

These are generally OK statuses.

* `Success`: the algorithm ran successfully and has a result; this includes cases where the algorithm converges to an infeasible point (NLP) or converges to a solution of a homogeneous self-dual problem and has a certificate of primal/dual infeasibility
* `InfeasibleNoResult`: the algorithm stopped because it decided that the problem is infeasible but does not have a result to return
* `UnboundedNoResult`: the algorithm stopped because it decided that the problem is unbounded but does not have a result to return
* `InfeasibleOrUnbounded`: the algorithm stopped because it decided that the problem is infeasible or unbounded (no result is available); this occasionally happens during MIP presolve

## Limits

The solver stopped because of some user-defined limit.
To be documented: `IterationLimit`, `TimeLimit`, `NodeLimit`, `SolutionLimit`, `MemoryLimit`, `ObjectiveLimit`, `NormLimit`, `OtherLimit`.

## Problematic

This group of statuses means that something unexpected or problematic happened.

* `SlowProgress`: the algorithm stopped because it was unable to continue making progress towards the solution
* `AlmostSuccess` should be used if there is additional information that relaxed convergence tolerances are satisfied

To be documented: `NumericalError`, `InvalidInstance`, `InvalidOption`, `Interrupted`, `OtherError`.

"""
@enum TerminationStatusCode Success AlmostSuccess InfeasibleNoResult UnboundedNoResult InfeasibleOrUnbounded IterationLimit TimeLimit NodeLimit SolutionLimit MemoryLimit ObjectiveLimit NormLimit OtherLimit SlowProgress NumericalError InvalidSolverInstance InvalidOption Interrupted OtherError

## Result status

"""
    ResultStatusCode

An Enum of possible values for the `PrimalStatus` and `DualStatus` attributes.
The values indicate how to interpret the result vector.

* `FeasiblePoint`
* `NearlyFeasiblePoint`
* `InfeasiblePoint`
* `InfeasibilityCertificate`
* `NearlyInfeasibilityCertificate`
* `ReductionCertificate`
* `NearlyReductionCertificate`
* `UnknownResultStatus`
* `OtherResultStatus`
"""
@enum ResultStatusCode FeasiblePoint NearlyFeasiblePoint InfeasiblePoint InfeasibilityCertificate NearlyInfeasibilityCertificate ReductionCertificate NearlyReductionCertificate UnknownResultStatus OtherResultStatus

"""
    PrimalStatus(N)
    PrimalStatus()

The `ResultStatusCode` of the primal result `N`.
If `N` is omitted, it defaults to 1.
"""
struct PrimalStatus <: AbstractInstanceAttribute
    N::Int
end
PrimalStatus() = PrimalStatus(1)

"""
    DualStatus(N)
    DualStatus()

The `ResultStatusCode` of the dual result `N`.
If `N` is omitted, it defaults to 1.
"""
struct DualStatus <: AbstractInstanceAttribute
    N::Int
end
DualStatus() = DualStatus(1)
