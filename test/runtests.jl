using Base.Test, Missings, Compat

@testset "Missings" begin
    # test promote rules
    @test promote_type(Missing, Missing) == Missing
    @test promote_type(Missing, Int) == Union{Missing, Int}
    @test promote_type(Int, Missing) == Union{Missing, Int}
    @test promote_type(Int, Any) == Any
    @test promote_type(Any, Any) == Any
    @test promote_type(Missing, Any) == Any
    @test promote_type(Any, Missing) == Any
    @test promote_type(Union{Int, Missing}, Missing) == Union{Int, Missing}
    @test promote_type(Missing, Union{Int, Missing}) == Union{Int, Missing}
    @test promote_type(Union{Int, Missing}, Int) == Union{Int, Missing}
    @test promote_type(Int, Union{Int, Missing}) == Union{Int, Missing}
    @test promote_type(Any, Union{Int, Missing}) == Any
    @test promote_type(Union{Int, Missing}, Union{Int, Missing}) == Union{Int, Missing}
    @test promote_type(Union{Float64, Missing}, Union{String, Missing}) == Any
    @test promote_type(Union{Float64, Missing}, Union{Int, Missing}) == Union{Float64, Missing}
    @test promote_type(Union{Void, Missing, Int}, Float64) == Any

    bit_operators = [&, |, ⊻]

    arithmetic_operators = [+, -, *, /, ^, Base.div, Base.mod, Base.fld, Base.rem]

    elementary_functions = [abs, abs2, sign,
                            acos, acosh, asin, asinh, atan, atanh, sin, sinh,
                            conj, cos, cosh, tan, tanh,
                            exp, exp2, expm1, log, log10, log1p, log2,
                            exponent, sqrt, gamma, lgamma,
                            identity, zero,
                            iseven, isodd, ispow2,
                            isfinite, isinf, isnan, iszero,
                            isinteger, isreal, isimag,
                            isempty, transpose, ctranspose, float]

    rounding_functions = [ceil, floor, round, trunc]

    # All unary operators return missing when evaluating missing
    for f in [!, +, -]
        @test ismissing(f(missing))
    end

    # All elementary functions return missing when evaluating missing
    for f in elementary_functions
        @test ismissing(f(missing))
    end

    # All rounding functions return missing when evaluating missing as first argument
    for f in rounding_functions
        @test ismissing(f(missing))
        @test ismissing(f(missing, 1))
        @test ismissing(f(missing, 1, 1))
        @test ismissing(f(Union{Int, Missing}, missing))
        @test_throws MissingException f(Int, missing)
    end

    @test zero(Union{Int, Missing}) === 0
    @test zero(Union{Float64, Missing}) === 0.0

    for T in (subtypes(Compat.Dates.DatePeriod)...,
              subtypes(Compat.Dates.TimePeriod)...)
        @test zero(Union{T, Missing}) === T(0)
    end

    # Comparison operators
    @test (missing == missing) === missing
    @test (1 == missing) === missing
    @test (missing == 1) === missing
    @test (missing != missing) === missing
    @test (1 != missing) === missing
    @test (missing != 1) === missing
    @test isequal(missing, missing)
    @test !isequal(1, missing)
    @test !isequal(missing, 1)
    @test (missing < missing) === missing
    @test (missing < 1) === missing
    @test (1 < missing) === missing
    @test (missing <= missing) === missing
    @test (missing <= 1) === missing
    @test (1 <= missing) === missing
    @test !isless(missing, missing)
    @test !isless(missing, 1)
    @test isless(1, missing)

    # All arithmetic operators return missing when operating on two missing's
    # All arithmetic operators return missing when operating on a scalar and an missing
    # All arithmetic operators return missing when operating on an missing and a scalar
    for f in arithmetic_operators
        @test ismissing(f(missing, missing))
        @test ismissing(f(1, missing))
        @test ismissing(f(missing, 1))
    end

    # All bit operators return missing when operating on two missing's
    for f in bit_operators
        @test ismissing(f(missing, missing))
    end

    @test ismissing(missing & true)
    @test ismissing(true & missing)
    @test !(missing & false)
    @test !(false & missing)
    @test ismissing(missing | false)
    @test ismissing(false | missing)
    @test missing | true
    @test true | missing
    @test ismissing(xor(missing, true))
    @test ismissing(xor(true, missing))
    @test ismissing(xor(missing, false))
    @test ismissing(xor(false, missing))

    @test ismissing(missing & 1)
    @test ismissing(1 & missing)
    @test ismissing(missing | 1)
    @test ismissing(1 | missing)
    @test ismissing(xor(missing, 1))
    @test ismissing(xor(1, missing))

    @test ismissing("a" * missing)
    @test ismissing(missing * "a")

    @test sprint(show, missing) == "missing"
    @test sprint(showcompact, missing) == "missing"
    @test sprint(show, [missing]) == "$Missing[missing]"
    @test sprint(show, [1 missing]) == "$(Union{Int, Missing})[1 missing]"
    b = IOBuffer()
    display(TextDisplay(b), [missing])
    @test String(take!(b)) == "1-element Array{$Missing,1}:\n missing"
    b = IOBuffer()
    display(TextDisplay(b), [1 missing])
    @test String(take!(b)) == "1×2 Array{$(Union{Int, Missing}),2}:\n 1  missing"

    x = Missings.replace([1, 2, missing, 4], 3)
    @test eltype(x) === Int
    @test length(x) == 4
    @test size(x) == (4,)
    @test collect(x) == collect(1:4)
    @test collect(x) isa Vector{Int}
    x = Missings.replace([1, 2, missing, 4], 3.0)
    @test eltype(x) === Int
    @test length(x) == 4
    @test size(x) == (4,)
    @test collect(x) == collect(1:4)
    @test collect(x) isa Vector{Int}
    x = Missings.replace([1 2; missing 4], 3)
    @test eltype(x) === Int
    @test length(x) == 4
    @test size(x) == (2, 2)
    @test collect(x) == [1 2; 3 4]
    @test collect(x) isa Matrix{Int}
    x = Missings.replace((v for v in [missing, 1, missing, 2, 4]), 0)
    @test length(x) == 5
    @test size(x) == (5,)
    @test eltype(x) === Any
    @test collect(x) == [0, 1, 0, 2, 4]
    @test collect(x) isa Vector{Int}

    x = Missings.fail([1, 2, 3, 4])
    @test eltype(x) === Int
    @test length(x) == 4
    @test size(x) == (4,)
    @test collect(x) == [1, 2, 3, 4]
    @test collect(x) isa Vector{Int}
    x = Missings.fail([1 2; 3 4])
    @test eltype(x) === Int
    @test length(x) == 4
    @test size(x) == (2, 2)
    @test collect(x) == [1 2; 3 4]
    @test collect(x) isa Matrix{Int}
    @test_throws MissingException collect(Missings.fail([1, 2, missing, 4]))
    x = Missings.fail(v for v in [1, 2, 4])
    @test eltype(x) === Any
    @test length(x) == 3
    @test size(x) == (3,)
    @test collect(x) == [1, 2, 4]
    @test collect(x) isa Vector{Int}

    x = skipmissing([1, 2, missing, 4])
    @test eltype(x) === Int
    @test collect(x) == [1, 2, 4]
    @test collect(x) isa Vector{Int}
    x = skipmissing([1  2; missing 4])
    @test eltype(x) === Int
    @test collect(x) == [1, 2, 4]
    @test collect(x) isa Vector{Int}
    x = collect(skipmissing([missing]))
    @test eltype(x) === Union{}
    @test isempty(collect(x))
    @test collect(x) isa Vector{Union{}}
    x = collect(skipmissing(Union{Int, Missing}[]))
    @test eltype(x) === Int
    @test isempty(collect(x))
    @test collect(x) isa Vector{Int}
    x = skipmissing([missing, missing, 1, 2, missing, 4, missing, missing])
    @test eltype(x) === Int
    @test collect(x) == [1, 2, 4]
    @test collect(x) isa Vector{Int}
    x = skipmissing(v for v in [missing, 1, missing, 2, 4])
    @test eltype(x) === Any
    @test collect(x) == [1, 2, 4]
    @test collect(x) isa Vector{Int}

    @test Missings.coalesce(missing, 1) === 1
    @test Missings.coalesce(1, missing) === 1
    @test Missings.coalesce(missing, missing) === missing
    @test Missings.coalesce.([missing, 1, missing], 0) == [0, 1, 0]
    @test Missings.coalesce.([missing, 1, missing], 0) isa Vector{Int}
    @test Missings.coalesce.([missing, 1, missing], [0, 10, 5]) == [0, 1, 5]
    @test Missings.coalesce.([missing, 1, missing], [0, 10, 5]) isa Vector{Int}
    @test isequal(Missings.coalesce.([missing, 1, missing], [0, missing, missing]), [0, 1, missing])
    # Fails in Julia 0.6 and 0.7.0-DEV.1556
    @test_broken Missings.coalesce.([missing, 1, missing], [0, missing, missing]) isa Vector{Union{Missing, Int}}

    @test levels(1:1) == levels([1]) == levels([1, missing]) == levels([missing, 1]) == [1]
    @test levels(2:-1:1) == levels([2, 1]) == levels([2, missing, 1]) == [1, 2]
    @test levels([missing, "a", "c", missing, "b"]) == ["a", "b", "c"]
    @test levels([Complex(0, 1), Complex(1, 0), missing]) == [Complex(0, 1), Complex(1, 0)]
    @test levels(sparse([0 3 2])) == [0, 2, 3]
    @test typeof(levels([1])) === typeof(levels([1, missing])) === Vector{Int}
    @test typeof(levels(["a"])) === typeof(levels(["a", missing])) === Vector{String}
    @test typeof(levels(sparse([1]))) === Vector{Int}
    @test isempty(levels([missing]))
    @test isempty(levels([]))

    x = convert(Vector{Union{Int, Missing}}, [1.0, missing])
    @test isa(x, Vector{Union{Int, Missing}})
    @test isequal(x, [1, missing])
    x = convert(Vector{Union{Int, Missing}}, [1.0])
    @test isa(x, Vector{Union{Int, Missing}})
    @test x == [1]
    x = convert(Vector{Union{Int, Missing}}, [missing])
    @test isa(x, Vector{Union{Int, Missing}})
    @test isequal(x, [missing])

    @test Missings.T(Union{Int, Missing}) == Int
    @test Missings.T(Any) == Any
    @test Missings.T(Missing) == Union{}

    @test isequal(missings(1), [missing])
    @test isequal(missings(Int, 1), [missing])
    @test missings(Int, 1) isa Vector{Union{Int, Missing}}
    @test isequal(missings(Union{Int, Missing}, 1, 2), [missing missing])
    @test missings(Union{Int, Missing}, 1, 2) isa Matrix{Union{Int, Missing}}
    @test Union{Int, Missing}[1,2,3] == (Union{Int, Missing})[1,2,3]

    @test convert(Union{Int, Missing}, 1.0) == 1

    # AbstractArray{>:Missing}

    @test ismissing([1, missing] == [1, missing])
    @test ismissing(["a", missing] == ["a", missing])
    @test ismissing(Any[1, missing] == Any[1, missing])
    @test ismissing(Any[missing] == Any[missing])
    @test ismissing([missing] == [missing])
    @test ismissing(Any[missing, 2] == Any[1, missing])
    @test ismissing([missing, false] == BitArray([true, false]))
    @test ismissing(Any[missing, false] == BitArray([true, false]))
    @test Union{Int, Missing}[1] == Union{Float64, Missing}[1.0]
    @test Union{Int, Missing}[1] == [1.0]
    @test Union{Bool, Missing}[true] == BitArray([true])
    @test !(Union{Int, Missing}[1] == [2])
    @test !([1] == Union{Int, Missing}[2])
    @test !(Union{Int, Missing}[1] == Union{Int, Missing}[2])

    @test ismissing([1, missing] != [1, missing])
    @test ismissing(["a", missing] != ["a", missing])
    @test ismissing(Any[1, missing] != Any[1, missing])
    @test ismissing(Any[missing] != Any[missing])
    @test ismissing([missing] != [missing])
    @test ismissing(Any[missing, 2] != Any[1, missing])
    @test ismissing([missing, false] != BitArray([true, false]))
    @test ismissing(Any[missing, false] != BitArray([true, false]))
    @test !(Union{Int, Missing}[1] != Union{Float64, Missing}[1.0])
    @test !(Union{Int, Missing}[1] != [1.0])
    @test !(Union{Bool, Missing}[true] != BitArray([true]))
    @test Union{Int, Missing}[1] != [2]
    @test [1] != Union{Int, Missing}[2]
    @test Union{Int, Missing}[1] != Union{Int, Missing}[2]

    @test any([true, missing])
    @test any(x -> x == 1, [1, missing])
    @test ismissing(any([false, missing]))
    @test ismissing(any(x -> x == 1, [2, missing]))
    @test ismissing(all([true, missing]))
    @test ismissing(all(x -> x == 1, [1, missing]))
    @test !all([false, missing])
    @test !all(x -> x == 1, [2, missing])
    @test 1 in [1, missing]
    @test ismissing(2 in [1, missing])
    @test ismissing(missing in [1, missing])

    @test isequal(float([1, missing]), [1, missing])
    @test float([1, missing]) isa Vector{Union{Float64, Missing}}
    @test isequal(float(Union{Int, Missing}[missing]), [missing])
    @test float(Union{Int, Missing}[missing]) isa Vector{Union{Float64, Missing}}
    @test float(Union{Int, Missing}[1]) == [1]
    @test float(Union{Int, Missing}[1]) isa Vector{Union{Float64, Missing}}
    @test isequal(float([missing]), [missing])
    @test float([missing]) isa Vector{Missing}

    # MissingException
    @test sprint(showerror, MissingException("test")) == "MissingException: test"
end
