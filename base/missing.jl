# This file is a part of Julia. License is MIT: https://julialang.org/license

# Missing, missing and ismissing are defined in essentials.jl

show(io::IO, x::Missing) = print(io, "missing")

"""
    MissingException(msg)

Exception thrown when a [`missing`](@ref) value is encountered in a situation
where it is not supported. The error message, in the `msg` field
may provide more specific details.
"""
struct MissingException <: Exception
    msg::AbstractString
end

showerror(io::IO, ex::MissingException) =
    print(io, "MissingException: ", ex.msg)

"""
    nonmissingtype(T::Type)

If `T` is a union of types containing `Missing`, return a new type with
`Missing` removed.

# Examples
```jldoctest
julia> nonmissingtype(Union{Int64,Missing})
Int64

julia> nonmissingtype(Any)
Any
```

!!! compat "Julia 1.3"
    This function is exported as of Julia 1.3.
"""
nonmissingtype(@nospecialize(T::Type)) = typesplit(T, Missing)

function nonmissingtype_checked(T::Type)
    R = nonmissingtype(T)
    R >: T && error("could not compute non-missing type")
    R <: Union{} && error("cannot convert a value to missing for assignment")
    return R
end

promote_rule(T::Type{Missing}, S::Type) = Union{S, Missing}
promote_rule(T::Type{Union{Nothing, Missing}}, S::Type) = Union{S, Nothing, Missing}
function promote_rule(T::Type{>:Union{Nothing, Missing}}, S::Type)
    R = nonnothingtype(T)
    R >: T && return Any
    T = R
    R = nonmissingtype(T)
    R >: T && return Any
    T = R
    R = promote_type(T, S)
    return Union{R, Nothing, Missing}
end
function promote_rule(T::Type{>:Missing}, S::Type)
    R = nonmissingtype(T)
    R >: T && return Any
    T = R
    R = promote_type(T, S)
    return Union{R, Missing}
end

convert(::Type{T}, x::T) where {T>:Missing} = x
convert(::Type{T}, x::T) where {T>:Union{Missing, Nothing}} = x
convert(::Type{T}, x) where {T>:Missing} = convert(nonmissingtype_checked(T), x)
convert(::Type{T}, x) where {T>:Union{Missing, Nothing}} = convert(nonmissingtype_checked(nonnothingtype_checked(T)), x)

# Comparison operators
==(::Missing, ::Missing) = missing
==(::Missing, ::Any) = missing
==(::Any, ::Missing) = missing
# To fix ambiguity
==(::Missing, ::WeakRef) = missing
==(::WeakRef, ::Missing) = missing
isequal(::Missing, ::Missing) = true
isequal(::Missing, ::Any) = false
isequal(::Any, ::Missing) = false
<(::Missing, ::Missing) = missing
<(::Missing, ::Any) = missing
<(::Any, ::Missing) = missing
isless(::Missing, ::Missing) = false
isless(::Missing, ::Any) = false
isless(::Any, ::Missing) = true
ispositive(::Missing) = missing
isnegative(::Missing) = missing
isapprox(::Missing, ::Missing; kwargs...) = missing
isapprox(::Missing, ::Any; kwargs...) = missing
isapprox(::Any, ::Missing; kwargs...) = missing

# Unary operators/functions
for f in (:(!), :(~), :(+), :(-), :(*), :(&), :(|), :(xor),
          :(zero), :(one), :(oneunit),
          :(isfinite), :(isinf), :(isodd),
          :(isinteger), :(isreal), :(isnan),
          :(iszero), :(transpose), :(adjoint), :(float), :(complex), :(conj),
          :(abs), :(abs2), :(iseven), :(ispow2),
          :(real), :(imag), :(sign), :(inv))
    @eval ($f)(::Missing) = missing
end
for f in (:(Base.zero), :(Base.one), :(Base.oneunit))
    @eval ($f)(::Type{Missing}) = missing
    @eval function $(f)(::Type{Union{T, Missing}}) where T
        T === Any && throw(MethodError($f, (Any,)))  # To prevent StackOverflowError
        $f(T)
    end
end
for f in (:(Base.float), :(Base.complex))
    @eval $f(::Type{Missing}) = Missing
    @eval function $f(::Type{Union{T, Missing}}) where T
        T === Any && throw(MethodError($f, (Any,)))  # To prevent StackOverflowError
        Union{$f(T), Missing}
    end
end

# Binary operators/functions
for f in (:(+), :(-), :(*), :(/), :(^), :(mod), :(rem))
    @eval begin
        # Scalar with missing
        ($f)(::Missing, ::Missing) = missing
        ($f)(::Missing, ::Number)  = missing
        ($f)(::Number,  ::Missing) = missing
    end
end

div(::Missing, ::Missing, r::RoundingMode) = missing
div(::Missing, ::Number, r::RoundingMode) = missing
div(::Number, ::Missing, r::RoundingMode) = missing

min(::Missing, ::Missing) = missing
min(::Missing, ::Any)     = missing
min(::Any,     ::Missing) = missing
max(::Missing, ::Missing) = missing
max(::Missing, ::Any)     = missing
max(::Any,     ::Missing) = missing
clamp(::Missing, lo, hi) = missing

missing_conversion_msg(@nospecialize T) =
    LazyString("cannot convert a missing value to type ", T, ": use Union{", T, ", Missing} instead")

# Rounding and related functions
round(::Missing, ::RoundingMode=RoundNearest; sigdigits::Integer=0, digits::Integer=0, base::Integer=0) = missing
round(::Type{>:Missing}, ::Missing, ::RoundingMode=RoundNearest) = missing
round(::Type{T}, ::Missing, ::RoundingMode=RoundNearest) where {T} =
    throw(MissingException(missing_conversion_msg(T)))
round(::Type{T}, x::Any, r::RoundingMode=RoundNearest) where {T>:Missing} = round(nonmissingtype_checked(T), x, r)
# to fix ambiguities
round(::Type{T}, x::Real, r::RoundingMode=RoundNearest) where {T>:Missing} = round(nonmissingtype_checked(T), x, r)
round(::Type{T}, x::Rational{Tr}, r::RoundingMode=RoundNearest) where {T>:Missing,Tr} = round(nonmissingtype_checked(T), x, r)
round(::Type{T}, x::Rational{Bool}, r::RoundingMode=RoundNearest) where {T>:Missing} = round(nonmissingtype_checked(T), x, r)

# to avoid ambiguity warnings
(^)(::Missing, ::Integer) = missing

# Bit operators
(&)(::Missing, ::Missing) = missing
(&)(a::Missing, b::Bool) = ifelse(b, missing, false)
(&)(b::Bool, a::Missing) = ifelse(b, missing, false)
(&)(::Missing, ::Integer) = missing
(&)(::Integer, ::Missing) = missing
(|)(::Missing, ::Missing) = missing
(|)(a::Missing, b::Bool) = ifelse(b, true, missing)
(|)(b::Bool, a::Missing) = ifelse(b, true, missing)
(|)(::Missing, ::Integer) = missing
(|)(::Integer, ::Missing) = missing
xor(::Missing, ::Missing) = missing
xor(a::Missing, b::Bool) = missing
xor(b::Bool, a::Missing) = missing
xor(::Missing, ::Integer) = missing
xor(::Integer, ::Missing) = missing

*(d::Missing, x::Union{AbstractString,AbstractChar}) = missing
*(d::Union{AbstractString,AbstractChar}, x::Missing) = missing

function float(A::AbstractArray{Union{T, Missing}}) where {T}
    U = typeof(float(zero(T)))
    convert(AbstractArray{Union{U, Missing}}, A)
end
float(A::AbstractArray{Missing}) = A

"""
    skipmissing(itr)

Return an iterator over the elements in `itr` skipping [`missing`](@ref) values.
The returned object can be indexed using indices of `itr` if the latter is indexable.
Indices corresponding to missing values are not valid: they are skipped by [`keys`](@ref)
and [`eachindex`](@ref), and a `MissingException` is thrown when trying to use them.

Use [`collect`](@ref) to obtain an `Array` containing the non-`missing` values in
`itr`. Note that even if `itr` is a multidimensional array, the result will always
be a `Vector` since it is not possible to remove missings while preserving dimensions
of the input.

See also [`coalesce`](@ref), [`ismissing`](@ref), [`something`](@ref).

# Examples
```jldoctest
julia> x = skipmissing([1, missing, 2])
skipmissing(Union{Missing, Int64}[1, missing, 2])

julia> sum(x)
3

julia> x[1]
1

julia> x[2]
ERROR: MissingException: the value at index (2,) is missing
[...]

julia> argmax(x)
3

julia> collect(keys(x))
2-element Vector{Int64}:
 1
 3

julia> collect(skipmissing([1, missing, 2]))
2-element Vector{Int64}:
 1
 2

julia> collect(skipmissing([1 missing; 2 missing]))
2-element Vector{Int64}:
 1
 2
```
"""
skipmissing(itr) = SkipMissing(itr)

struct SkipMissing{T}
    x::T
end
IteratorSize(::Type{<:SkipMissing}) = SizeUnknown()
IteratorEltype(::Type{SkipMissing{T}}) where {T} = IteratorEltype(T)
eltype(::Type{SkipMissing{T}}) where {T} = nonmissingtype(eltype(T))

function iterate(itr::SkipMissing, state...)
    y = iterate(itr.x, state...)
    y === nothing && return nothing
    item, state = y
    while ismissing(item)
        y = iterate(itr.x, state)
        y === nothing && return nothing
        item, state = y
    end
    item, state
end

IndexStyle(::Type{<:SkipMissing{T}}) where {T} = IndexStyle(T)
eachindex(itr::SkipMissing) =
    Iterators.filter(i -> !ismissing(@inbounds(itr.x[i])), eachindex(itr.x))
keys(itr::SkipMissing) =
    Iterators.filter(i -> !ismissing(@inbounds(itr.x[i])), keys(itr.x))
@propagate_inbounds function getindex(itr::SkipMissing, I...)
    v = itr.x[I...]
    ismissing(v) && throw(MissingException(LazyString("the value at index ", I, " is missing")))
    v
end

function show(io::IO, s::SkipMissing)
    print(io, "skipmissing(")
    show(io, s.x)
    print(io, ')')
end

# Optimized mapreduce implementation
# The generic method is faster when !(eltype(A) >: Missing) since it does not need
# additional loops to identify the two first non-missing values of each block
mapreduce(f, op, itr::SkipMissing{<:AbstractArray}) =
    _mapreduce(f, op, IndexStyle(itr.x), eltype(itr.x) >: Missing ? itr : itr.x)

function _mapreduce(f, op, ::IndexLinear, itr::SkipMissing{<:AbstractArray})
    A = itr.x
    ai = missing
    inds = LinearIndices(A)
    i = first(inds)
    ilast = last(inds)
    for outer i in i:ilast
        @inbounds ai = A[i]
        !ismissing(ai) && break
    end
    ismissing(ai) && return mapreduce_empty(f, op, eltype(itr))
    a1::eltype(itr) = ai
    i == typemax(typeof(i)) && return mapreduce_first(f, op, a1)
    i += 1
    ai = missing
    for outer i in i:ilast
        @inbounds ai = A[i]
        !ismissing(ai) && break
    end
    ismissing(ai) && return mapreduce_first(f, op, a1)
    # We know A contains at least two non-missing entries: the result cannot be nothing
    something(mapreduce_impl(f, op, itr, first(inds), last(inds)))
end

_mapreduce(f, op, ::IndexCartesian, itr::SkipMissing) = mapfoldl(f, op, itr)

mapreduce_impl(f, op, A::SkipMissing, ifirst::Integer, ilast::Integer) =
    mapreduce_impl(f, op, A, ifirst, ilast, pairwise_blocksize(f, op))

# Returns nothing when the input contains only missing values, and Some(x) otherwise
@noinline function mapreduce_impl(f, op, itr::SkipMissing{<:AbstractArray},
                                  ifirst::Integer, ilast::Integer, blksize::Int)
    A = itr.x
    if ifirst > ilast
        return nothing
    elseif ifirst == ilast
        @inbounds a1 = A[ifirst]
        if ismissing(a1)
            return nothing
        else
            return Some(mapreduce_first(f, op, a1))
        end
    elseif ilast - ifirst < blksize
        # sequential portion
        ai = missing
        i = ifirst
        for outer i in i:ilast
            @inbounds ai = A[i]
            !ismissing(ai) && break
        end
        ismissing(ai) && return nothing
        a1 = ai::eltype(itr)
        i == typemax(typeof(i)) && return Some(mapreduce_first(f, op, a1))
        i += 1
        ai = missing
        for outer i in i:ilast
            @inbounds ai = A[i]
            !ismissing(ai) && break
        end
        ismissing(ai) && return Some(mapreduce_first(f, op, a1))
        a2 = ai::eltype(itr)
        i == typemax(typeof(i)) && return Some(op(f(a1), f(a2)))
        i += 1
        v = op(f(a1), f(a2))
        @simd for i = i:ilast
            @inbounds ai = A[i]
            if !ismissing(ai)
                v = op(v, f(ai))
            end
        end
        return Some(v)
    else
        # pairwise portion
        imid = ifirst + (ilast - ifirst) >> 1
        v1 = mapreduce_impl(f, op, itr, ifirst, imid, blksize)
        v2 = mapreduce_impl(f, op, itr, imid+1, ilast, blksize)
        if v1 === nothing && v2 === nothing
            return nothing
        elseif v1 === nothing
            return v2
        elseif v2 === nothing
            return v1
        else
            return Some(op(something(v1), something(v2)))
        end
    end
end

"""
    filter(f, itr::SkipMissing{<:AbstractArray})

Return a vector similar to the array wrapped by the given `SkipMissing` iterator
but with all missing elements and those for which `f` returns `false` removed.

!!! compat "Julia 1.2"
    This method requires Julia 1.2 or later.

# Examples
```jldoctest
julia> x = [1 2; missing 4]
2×2 Matrix{Union{Missing, Int64}}:
 1         2
  missing  4

julia> filter(isodd, skipmissing(x))
1-element Vector{Int64}:
 1
```
"""
function filter(f, itr::SkipMissing{<:AbstractArray})
    y = similar(itr.x, eltype(itr), 0)
    for xi in itr.x
        if !ismissing(xi) && f(xi)
            push!(y, xi)
        end
    end
    y
end

"""
    coalesce(x...)

Return the first value in the arguments which is not equal to [`missing`](@ref),
if any. Otherwise return `missing`.

See also [`skipmissing`](@ref), [`something`](@ref), [`@coalesce`](@ref).

# Examples

```jldoctest
julia> coalesce(missing, 1)
1

julia> coalesce(1, missing)
1

julia> coalesce(nothing, 1)  # returns `nothing`

julia> coalesce(missing, missing)
missing
```
"""
function coalesce end

coalesce() = missing
coalesce(x::Missing, y...) = coalesce(y...)
coalesce(x::Any, y...) = x


"""
    @coalesce(x...)

Short-circuiting version of [`coalesce`](@ref).

# Examples
```jldoctest
julia> f(x) = (println("f(\$x)"); missing);

julia> a = 1;

julia> a = @coalesce a f(2) f(3) error("`a` is still missing")
1

julia> b = missing;

julia> b = @coalesce b f(2) f(3) error("`b` is still missing")
f(2)
f(3)
ERROR: `b` is still missing
[...]
```

!!! compat "Julia 1.7"
    This macro is available as of Julia 1.7.
"""
macro coalesce(args...)
    expr = :(missing)
    for arg in reverse(args)
        expr = :(!ismissing((val = $(esc(arg));)) ? val : $expr)
    end
    return :(let val; $expr; end)
end
