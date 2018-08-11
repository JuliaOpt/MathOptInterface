"""
    UnsupportedError <: Exception

Abstract type for error thrown when an element is not supported by the model.
"""
abstract type UnsupportedError <: Exception end

"""
    element_name(err::UnsupportedError)

Return the name of the element that is not supported
"""
function element_name end

function Base.showerror(io::IO, err::UnsupportedError)
    print(io, typeof(err), ": ", element_name(err),
          " is not supported by the the model")
    m = message(err)
    if Base.isempty(m)
        print(io, ".")
    else
        print(io, ": ", m)
    end
end

"""
    CannotTryResetError <: Exception

Abstract type for error thrown when an operation is supported but cannot be
applied in the current state of the model.
"""
abstract type CannotTryResetError <: Exception end

"""
    operation_name(err::CannotTryResetError)

Return the name of the operation throwing the error in a gerund (i.e. -ing
form).
"""
function operation_name end

function Base.showerror(io::IO, err::CannotTryResetError)
    print(io, typeof(err), ": ", operation_name(err),
          " cannot be performed")
    m = message(err)
    if Base.isempty(m)
        print(io, ".")
    else
        print(io, ": ", m)
    end
    print(io, " You may want to use a `CachingOptimizer` in `Automatic` mode",
          " or you may need to call `resetoptimizer!` before doing this",
          " operation if the `CachingOptimizer` is in `Manual` mode.")
end

"""
    message(err::Union{UnsupportedError, CannotTryResetError})

Return a `String` containing a human-friendly explanation why the operation
is not supported/cannot be performed. It is printed in the error message if it
is not empty. By convention, it should be stored in the `message` field, it is
it the case, the `message` method does not have to be implemented.
"""
message(err::Union{UnsupportedError, CannotTryResetError}) = err.message
