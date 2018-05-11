"""
    basic_constraint_tests(f::Function, model::MOI.ModelLike, config::TestConfig, set::MOI.AbstractSet, N::Int; delete::Bool=true)

Test some basic constraint tests. `f` is a function that takes a vector of `N`
variables and returns a constraint function.

If `delete=true`, test `candelete` and `delete!`.

### Example

    basic_constraint_tests(model, config, MOI.LessThan(1.0), 1; delete=false) do x
        MOI.ScalarAffineFunction(model, [x], [1.0], 0.0)
    end
"""
function basic_constraint_tests(f::Function, model::MOI.ModelLike, config::TestConfig, set::MOI.AbstractSet, N::Int=1; delete::Bool=true)
    MOI.empty!(model)
    x = MOI.addvariables!(model, N)
    constraint_function = f(x)
    F, S = typeof(constraint_function), typeof(set)

    @testset "NumberOfConstraints" begin
        @test MOI.canget(model, MOI.NumberOfConstraints{F,S}())
    end

    @testset "canaddconstraint" begin
        @test MOI.canaddconstraint(model, F, S)
    end

    @testset "addconstraint!" begin
        n = MOI.get(model, MOI.NumberOfConstraints{F,S}())
        c = MOI.addconstraint!(model, constraint_function, set)
        @test MOI.get(model, MOI.NumberOfConstraints{F,S}()) == n + 1
    end

    @testset "addconstraints!" begin
        n = MOI.get(model, MOI.NumberOfConstraints{F,S}())
        cc = MOI.addconstraints!(model,
            [constraint_function, constraint_function],
            [set, set]
        )
        @test MOI.get(model, MOI.NumberOfConstraints{F,S}()) == n + 2
    end

    @testset "ListOfConstraintIndices" begin
        @test MOI.canget(model, MOI.ListOfConstraintIndices{F,S}())
        c_indices = MOI.get(model, MOI.ListOfConstraintIndices{F,S}())
        @test length(c_indices) == MOI.get(model, MOI.NumberOfConstraints{F,S}()) == 3
    end

    @testset "isvalid" begin
        c_indices = MOI.get(model, MOI.ListOfConstraintIndices{F,S}())
        @test length(c_indices) == 3  # check that we've added a constraint
        @test all(MOI.isvalid.(model, c_indices))
    end

    if delete
        @testset "candelete" begin
            c_indices = MOI.get(model, MOI.ListOfConstraintIndices{F,S}())
            @test length(c_indices) == 3  # check that we've added a constraint
            @test MOI.candelete(model, c_indices[1])
        end
        @testset "delete!" begin
            c_indices = MOI.get(model, MOI.ListOfConstraintIndices{F,S}())
            @test length(c_indices) == 3  # check that we've added a constraint
            MOI.delete!(model, c_indices[1])
            @test MOI.get(model, MOI.NumberOfConstraints{F,S}()) == length(c_indices)-1 == 2
            @test !MOI.isvalid(model, c_indices[1])
        end
    end
end

"""
    test_scalaraffine_in_lessthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `ScalarAffineFunction{Float64}`-in-`LessThan{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_scalaraffine_in_lessthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.LessThan(1.0)) do x
        MOI.ScalarAffineFunction(x, [1.0], 0.0)
    end
end
unittests["test_scalaraffine_in_lessthan"] = test_scalaraffine_in_lessthan


"""
    test_scalaraffine_in_greaterthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `ScalarAffineFunction{Float64}`-in-`GreaterThan{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_scalaraffine_in_greaterthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.GreaterThan(1.0)) do x
        MOI.ScalarAffineFunction(x, [1.0], 0.0)
    end
end
unittests["test_scalaraffine_in_greaterthan"] = test_scalaraffine_in_greaterthan

"""
    test_scalaraffine_in_equalto(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `ScalarAffineFunction{Float64}`-in-`EqualTo{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_scalaraffine_in_equalto(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.EqualTo(1.0)) do x
        MOI.ScalarAffineFunction(x, [1.0], 0.0)
    end
end
unittests["test_scalaraffine_in_equalto"] = test_scalaraffine_in_equalto

"""
    test_scalaraffine_in_interval(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `ScalarAffineFunction{Float64}`-in-`Interval{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_scalaraffine_in_interval(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.Interval(0.0, 1.0)) do x
        MOI.ScalarAffineFunction(x, [1.0], 0.0)
    end
end
unittests["test_scalaraffine_in_interval"] = test_scalaraffine_in_interval

"""
    test_singlevariable_in_lessthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `SingleVariable`-in-`LessThan{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_singlevariable_in_lessthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.LessThan(1.0)) do x
        MOI.SingleVariable(x[1])
    end
end
unittests["test_singlevariable_in_lessthan"] = test_singlevariable_in_lessthan


"""
    test_singlevariable_in_greaterthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `SingleVariable`-in-`GreaterThan{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_singlevariable_in_greaterthan(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.GreaterThan(1.0)) do x
        MOI.SingleVariable(x[1])
    end
end
unittests["test_singlevariable_in_greaterthan"] = test_singlevariable_in_greaterthan

"""
    test_singlevariable_in_equalto(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `SingleVariable`-in-`EqualTo{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_singlevariable_in_equalto(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.EqualTo(1.0)) do x
        MOI.SingleVariable(x[1])
    end
end
unittests["test_singlevariable_in_equalto"] = test_singlevariable_in_equalto

"""
    test_singlevariable_in_interval(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)

Basic tests for constraints of the form `SingleVariable`-in-`Interval{Float64}`.

If `delete=true`, test `MOI.candelete` and `MOI.delete!`.
"""
function test_singlevariable_in_interval(model::MOI.ModelLike, config::TestConfig; delete::Bool=true)
    basic_constraint_tests(model, config, MOI.Interval(0.0, 1.0)) do x
        MOI.SingleVariable(x[1])
    end
end
unittests["test_singlevariable_in_interval"] = test_singlevariable_in_interval
