#=
    Functions in this file test functionality relating to variables in MOI.

### Functionality currently tested
    - canaddvariable
    - addvariables!
    - addvariable!
    - deleting variables
    - get/set! VariableName
    - isvalid for VariableIndex
    - get VariableIndex by name
    - NumberOfVariables

### Functionality not yet tested
    - VariablePrimalStart
    - VariablePrimal
    - VariableBasisStatus
    - ListOfVariableIndices
=#

"""
    add_variable(model::MOI.ModelLike, config::TestConfig)

Test adding a single variable.
"""
function add_variable(model::MOI.ModelLike, config::TestConfig)
    MOI.empty!(model)
    @test MOI.isempty(model)
    @test MOI.canaddvariable(model)
    @test MOI.get(model, MOI.NumberOfVariables()) == 0
    v = MOI.addvariable!(model)
    @test MOI.get(model, MOI.NumberOfVariables()) == 1
end
unittests["add_variable"]     = add_variable

"""
    add_variables(model::MOI.ModelLike, config::TestConfig)

Test adding multiple variables.
"""
function add_variables(model::MOI.ModelLike, config::TestConfig)
    MOI.empty!(model)
    @test MOI.isempty(model)
    @test MOI.canaddvariable(model)
    @test MOI.get(model, MOI.NumberOfVariables()) == 0
    v = MOI.addvariables!(model, 2)
    @test MOI.get(model, MOI.NumberOfVariables()) == 2
end
unittests["add_variables"] = add_variables

"""
    delete_variable(model::MOI.ModelLike, config::TestConfig)

Tess adding, and then deleting, a single variable.
"""
function delete_variable(model::MOI.ModelLike, config::TestConfig)
    MOI.empty!(model)
    @test MOI.isempty(model)
    @test MOI.canaddvariable(model)
    @test MOI.get(model, MOI.NumberOfVariables()) == 0
    v = MOI.addvariable!(model)
    @test MOI.get(model, MOI.NumberOfVariables()) == 1
    @test MOI.candelete(model, v)
    MOI.delete!(model, v)
    @test MOI.get(model, MOI.NumberOfVariables()) == 0
end
unittests["delete_variable"] = delete_variable

"""
    delete_variables(model::MOI.ModelLike, config::TestConfig)

Test adding, and then deleting, multiple variables.
"""
function delete_variables(model::MOI.ModelLike, config::TestConfig)
    MOI.empty!(model)
    @test MOI.isempty(model)
    @test MOI.canaddvariable(model)
    @test MOI.get(model, MOI.NumberOfVariables()) == 0
    v = MOI.addvariables!(model, 2)
    @test MOI.get(model, MOI.NumberOfVariables()) == 2
    @test MOI.candelete(model, v)
    MOI.delete!(model, v)
    @test MOI.get(model, MOI.NumberOfVariables()) == 0
    v = MOI.addvariables!(model, 2)
    @test MOI.get(model, MOI.NumberOfVariables()) == 2
    @test MOI.candelete(model, v[1])
    MOI.delete!(model, v[1])
    @test MOI.get(model, MOI.NumberOfVariables()) == 1
    @test !MOI.candelete(model, v[1])
    @test MOI.candelete(model, v[2])
    @test !MOI.isvalid(model, v[1])
    @test MOI.isvalid(model, v[2])
end
unittests["delete_variables"] = delete_variable

"""
    getvariable(model::MOI.ModelLike, config::TestConfig)

Test getting variables by name.
"""
function getvariable(model::MOI.ModelLike, config::TestConfig)
    MOI.empty!(model)
    MOIU.loadfromstring!(model,"""
        variables: x
        minobjective: 2.0x
        c1: x >= 1.0
        c2: x <= 2.0
    """)
    @test MOI.canget(model, MOI.VariableIndex, "x")
    @test !MOI.canget(model, MOI.VariableIndex, "y")
    x = MOI.get(model, MOI.VariableIndex, "x")
    @test MOI.isvalid(model, x)
end
unittests["getvariable"] = getvariable

"""
    variablenames(model::MOI.ModelLike, config::TestConfig)

Test getting and setting variable names.
"""
function variablenames(model::MOI.ModelLike, config::TestConfig)
    MOI.empty!(model)
    v = MOI.addvariable!(model)
    @test MOI.get(model, MOI.VariableName(), v) == ""
    @test MOI.canset(model, MOI.VariableName(), typeof(v))
    MOI.set!(model, MOI.VariableName(), v, "x")
    @test MOI.get(model, MOI.VariableName(), v) == "x"
    MOI.set!(model, MOI.VariableName(), v, "y")
    @test MOI.get(model, MOI.VariableName(), v) == "y"
    x = MOI.addvariable!(model)
    MOI.set!(model, MOI.VariableName(), x, "x")
    @test MOI.get(model, MOI.VariableName(), x) == "x"
end
unittests["variablenames"] = variablenames

"""
    solve_with_upperbound(model::MOI.ModelLike, config::TestConfig)

Test setting the upper bound of a variable, confirm that it solves correctly,
and if `config.duals=true`, check that the dual is computed correctly.
"""
function solve_with_upperbound(model::MOI.ModelLike, config::TestConfig)
    atol, rtol = config.atol, config.rtol
    MOI.empty!(model)
    @test MOI.isempty(model)
    MOIU.loadfromstring!(model,"""
        variables: x
        maxobjective: 2.0x
        c1: x <= 1.0
        c2: x >= 0.0
    """)
    x  = MOI.get(model, MOI.VariableIndex, "x")
    c1 = MOI.get(model, MOI.ConstraintIndex{MOI.SingleVariable,MOI.LessThan{Float64}}, "c1")
    c2 = MOI.get(model, MOI.ConstraintIndex{MOI.SingleVariable,MOI.GreaterThan{Float64}}, "c2")
    if config.solve
        test_model_solution(model, config;
            objective_value   = 2.0,
            variable_primal   = [(x, 1.0)],
            constraint_primal = [(c1, 1.0), (c2, 1.0)],
            constraint_dual   = [(c1, -2.0), (c2, 0.0)]
        )
    end
end
unittests["solve_with_upperbound"] = solve_with_upperbound

"""
    solve_with_lowerbound(model::MOI.ModelLike, config::TestConfig)

Test setting the lower bound of a variable, confirm that it solves correctly,
and if `config.duals=true`, check that the dual is computed correctly.
"""
function solve_with_lowerbound(model::MOI.ModelLike, config::TestConfig)
    atol, rtol = config.atol, config.rtol
    MOI.empty!(model)
    @test MOI.isempty(model)
    MOIU.loadfromstring!(model,"""
        variables: x
        minobjective: 2.0x
        c1: x >= 1.0
        c2: x <= 2.0
    """)
    x = MOI.get(model, MOI.VariableIndex, "x")
    c1 = MOI.get(model, MOI.ConstraintIndex{MOI.SingleVariable,MOI.GreaterThan{Float64}}, "c1")
    c2 = MOI.get(model, MOI.ConstraintIndex{MOI.SingleVariable,MOI.LessThan{Float64}}, "c2")
    if config.solve
        test_model_solution(model, config;
            objective_value   = 2.0,
            variable_primal   = [(x, 1.0)],
            constraint_primal = [(c1, 1.0), (c2, 1.0)],
            constraint_dual   = [(c1, 2.0), (c2, 0.0)]
        )
    end
end
unittests["solve_with_lowerbound"] = solve_with_lowerbound
