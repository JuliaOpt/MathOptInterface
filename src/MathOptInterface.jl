module MathOptInterface

"""
    ModelLike

Abstract supertype for objects that implement the "Model" interface for defining
an optimization problem.
"""
abstract type ModelLike end

# This allows to use `ModelLike`s in broadcast calls without the need to
# embed it in a `Ref`
Base.broadcastable(model::ModelLike) = Ref(model)

function Base.show(io::IO, model::ModelLike)
    return Utilities.print_with_acronym(io, summary(model))
end

"""
    AbstractOptimizer

Abstract supertype for objects representing an instance of an optimization problem
tied to a particular solver. This is typically a solver's in-memory representation.
In addition to `ModelLike`, `AbstractOptimizer` objects let you solve the
model and query the solution.
"""
abstract type AbstractOptimizer <: ModelLike end

"""
    optimize!(optimizer::AbstractOptimizer)

Start the solution procedure.
"""
function optimize! end

"""
    compute_conflict!(optimizer::AbstractOptimizer)

Computes a minimal subset of constraints such that the model with the other
constraint removed is still infeasible.

Some solvers call a set of conflicting constraints an Irreducible Inconsistent
Subsystem (IIS).

See also [`ConflictStatus`](@ref) and [`ConstraintConflictStatus`](@ref).

### Note

If the model is modified after a call to `compute_conflict!`, the implementor
is not obliged to purge the conflict. Any calls to the above attributes may
return values for the original conflict without a warning. Similarly, when
modifying the model, the conflict can be discarded.
"""
function compute_conflict! end

"""
    write_to_file(model::ModelLike, filename::String)

Writes the current model data to the given file.
Supported file types depend on the model type.
"""
function write_to_file end

"""
    read_from_file(model::ModelLike, filename::String)

Read the file `filename` into the model `model`. If `model` is non-empty, this may
throw an error.

Supported file types depend on the model type.

### Note

Once the contents of the file are loaded into the model, users can query the variables via
`get(model, ListOfVariableIndices())`. However, some filetypes, such as LP files, do not
maintain an explicit ordering of the variables. Therefore, the returned list may be in an
arbitrary order. To avoid depending on the order of the indices, users should look up each
variable index by name: `get(model, VariableIndex, "name")`.
"""
function read_from_file end

"""
    is_empty(model::ModelLike)

Returns `false` if the `model` has any model attribute set or has any variables or constraints.
Note that an empty model can have optimizer attributes set.
"""
function is_empty end

"""
    empty!(model::ModelLike)

Empty the model, that is, remove all variables, constraints and model attributes but not optimizer attributes.
"""
function empty! end

"""
    supports_incremental_interface(model::ModelLike, copy_names::Bool)

Return a `Bool` indicating whether `model` supports building incrementally via
[`add_variable`](@ref) and [`add_constraint`](@ref).

`copy_names` is a `Bool` indicating whether the user wishes to set
[`VariableName`](@ref) and [`ConstraintName`](@ref) attributes.
If `model` supports the incremental interface but does not support name
attributes, define
```julia
supports_incremental_interface(::MyNewModel, copy_names::Bool) = !copy_names
```

The main purpose of this function is to determine whether a model can be loaded
into `model` incrementally or whether it should be cached and copied at once
instead.

This is used in two places to determine whether to add a cache:
1. A first cache can be used to store the model as entered by the user as well
   as the names of variables and constraints. This cache is created if this
   function returns `false` when `copy_names` is `true`.
2. If bridges are used, then a second cache can be used to store the bridged
   model with unnamed variables and constraints. This cache is created if this
   function returns `false` when `copy_names` is `false`.
```
"""
supports_incremental_interface(::ModelLike, ::Bool) = false

"""
    copy_to(dest::ModelLike, src::ModelLike; copy_names=true, warn_attributes=true)

Copy the model from `src` into `dest`. The target `dest` is emptied, and all
previous indices to variables or constraints in `dest` are invalidated. Returns
a dictionary-like object that translates variable and constraint indices from
the `src` model to the corresponding indices in the `dest` model.

If `copy_names` is `false`, the `Name`, `VariableName` and `ConstraintName`
attributes are not copied even if they are set in `src`. If a constraint that
is copied from `src` is not supported by `dest` then an
[`UnsupportedConstraint`](@ref) error is thrown. Similarly, if a model, variable
or constraint attribute that is copied from `src` is not supported by `dest`
then an [`UnsupportedAttribute`](@ref) error is thrown. Unsupported *optimizer*
attributes are treated differently:

* If `warn_attributes` is `true`, a warning is displayed, otherwise,
* the attribute is silently ignored.

### Example

```julia
# Given empty `ModelLike` objects `src` and `dest`.

x = add_variable(src)

is_valid(src, x)   # true
is_valid(dest, x)  # false (`dest` has no variables)

index_map = copy_to(dest, src)
is_valid(dest, x) # false (unless index_map[x] == x)
is_valid(dest, index_map[x]) # true
```
"""
function copy_to end

import MutableArithmetics

"""
    AbstractFunction

Abstract supertype for function objects.
"""
abstract type AbstractFunction <: MutableArithmetics.AbstractMutable end

"""
    AbstractScalarFunction

Abstract supertype for scalar-valued function objects.
"""
abstract type AbstractScalarFunction <: AbstractFunction end

include("error.jl")
include("indextypes.jl")
include("functions.jl")
include("sets.jl")
include("attributes.jl")
include("constraints.jl")
include("modifications.jl")
include("variables.jl")
include("nlp.jl")

if VERSION > v"1.4.2"
    include("precompile.jl")
end

# submodules
include("Utilities/Utilities.jl") # MOI.Utilities
include("Test/Test.jl")
include("Bridges/Bridges.jl")     # MOI.Bridges
include("Benchmarks/Benchmarks.jl")
include("FileFormats/FileFormats.jl")

include("instantiate.jl")
include("deprecate.jl")
include("DeprecatedTest/DeprecatedTest.jl")

end
