# Continuous conic problems

function contconictest(solver::MOI.AbstractSolver, ε=Base.rtoldefault(Float64))

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorVariablewiseFunction,MOI.Nonnegative),(MOI.VectorAffineFunction{Float64},MOI.Nonnegative)])
        @testset "LIN1" begin
            # linear conic problem
            # min -3x - 2y - 4z
            # st    x +  y +  z == 3
            #            y +  z == 2
            #       x>=0 y>=0 z>=0
            # Opt obj = -11, soln x = 1, y = 0, z = 2

            m = MOI.SolverInstance(solver)

            v = MOI.addvariables!(m, 3)
            @test MOI.getattribute(m, MOI.NumberOfVariables()) == 3

            vc = MOI.addconstraint!(m, MOI.VectorVariablewiseFunction(v), MOI.Nonnegative(3))
            c = MOI.addconstraint!(m, MOI.VectorAffineFunction([1,1,1,2,2], [v;v[2];v[3]], ones(5), [-3.0,-2.0]), MOI.Zero(2))
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorVariablewiseFunction,MOI.Nonnegative}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zero}()) == 1
            loc = MOI.getattribute(m, MOI.ListOfConstraints())
            @test length(loc) == 2
            @test (MOI.VectorVariablewiseFunction,MOI.Nonnegative) in loc
            @test (MOI.VectorAffineFunction{Float64},MOI.Zero) in loc

            MOI.setobjective!(m, MOI.MinSense, MOI.ScalarAffineFunction(v, [-3.0, -2.0, -4.0], 0.0))

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ -11 atol=ε

            @test MOI.cangetattribute(m, MOI.VariablePrimal(), v)
            @test MOI.getattribute(m, MOI.VariablePrimal(), v) ≈ [1, 0, 2] atol=ε

            @test MOI.cangetattribute(m, MOI.ConstraintDual(), c)
            @test MOI.getattribute(m, MOI.ConstraintDual(), c) ≈ [3, 1] atol=ε

            # TODO var dual and con primal
        end
    end


    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.NonNegative),(MOI.VectorAffineFunction{Float64},MOI.Nonnegative)])
        @testset "LIN1A" begin
            # Same as LIN1 but variable bounds enforced with VectorAffineFunction

            m = MOI.SolverInstance(solver)

            v = MOI.addvariables!(m, 3)
            @test MOI.getattribute(m, MOI.NumberOfVariables()) == 3

            vc = MOI.addconstraint!(m, MOI.VectorAffineFunction([1,2,3], v, ones(3), zeros(3)), MOI.Nonnegative(3))
            c = MOI.addconstraint!(m, MOI.VectorAffineFunction([1,1,1,2,2], [v;v[2];v[3]], ones(5), [-3.0,-2.0]), MOI.Zero(2))
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonnegative}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zero}()) == 1

            MOI.setobjective!(m, MOI.MinSense, MOI.ScalarAffineFunction(v, [-3.0, -2.0, -4.0], 0.0))

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ -11 atol=ε

            @test MOI.cangetattribute(m, MOI.VariablePrimal(), v)
            @test MOI.getattribute(m, MOI.VariablePrimal(), v) ≈ [1, 0, 2] atol=ε

            @test MOI.cangetattribute(m, MOI.ConstraintDual(), c)
            @test MOI.getattribute(m, MOI.ConstraintDual(), c) ≈ [3, 1] atol=ε

            # TODO var dual and con primal
        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Zero),(MOI.VectorVariablewiseFunction,MOI.Nonnegative),(MOI.VectorVariablewiseFunction,MOI.Nonpositive)])
        @testset "LIN2" begin
            # mixed cones
            # min  3x + 2y - 4z + 0s
            # st    x           -  s  == -4    (i.e. x >= -4)
            #            y            == -3
            #       x      +  z       == 12
            #       x free
            #       y <= 0
            #       z >= 0
            #       s zero
            # Opt solution = -82
            # x = -4, y = -3, z = 16, s == 0


            m = MOI.SolverInstance(solver)

            x,y,z,s = MOI.addvariables!(m, 4)
            @test MOI.getattribute(m, MOI.NumberOfVariables()) == 4


            MOI.setobjective!(m, MOI.MinSense, MOI.ScalarAffineFunction([x,y,z], [3.0, 2.0, -4.0], 0.0))


            c = MOI.addconstraint!(m, MOI.VectorAffineFunction([1,1,2,3,3], [x,s,y,x,z], [1.0,-1.0,1.0,1.0,1.0], [4.0,3.0,-12.0]), MOI.Zero(3))

            vy = MOI.addconstraint!(m, MOI.VectorVariablewiseFunction([y]), MOI.Nonpositive(1))
            vz = MOI.addconstraint!(m, MOI.VectorVariablewiseFunction([z]), MOI.Nonnegative(1))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zero}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonpositive}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonnegative}()) == 1

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ -82 atol=ε

            @test MOI.cangetattribute(m, MOI.VariablePrimal(), x)
            @test MOI.getattribute(m, MOI.VariablePrimal(), x) ≈ -4 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), y) ≈ -3 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), z) ≈ 16 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), s) ≈ 0 atol=ε

            @test MOI.cangetattribute(m, MOI.ConstraintDual(), c)
            @test MOI.getattribute(m, MOI.ConstraintDual(), c) ≈ [-7, -2, 4] atol=ε

            # TODO var dual and con primal

        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Zero),(MOI.VectorAffineFunction{Float64},MOI.Nonnegative),(MOI.VectorAffineFunction{Float64},MOI.Nonpositive)])
        @testset "LIN2A" begin
            # mixed cones
            # same as LIN2 but with variable bounds enforced with VectorAffineFunction
            # min  3x + 2y - 4z + 0s
            # st    x           -  s  == -4    (i.e. x >= -4)
            #            y            == -3
            #       x      +  z       == 12
            #       x free
            #       y <= 0
            #       z >= 0
            #       s zero
            # Opt solution = -82
            # x = -4, y = -3, z = 16, s == 0

            m = MOI.SolverInstance(solver)

            x,y,z,s = MOI.addvariables!(m, 4)
            @test MOI.getattribute(m, MOI.NumberOfVariables()) == 4


            MOI.setobjective!(m, MOI.MinSense, MOI.ScalarAffineFunction([x,y,z], [3.0, 2.0, -4.0], 0.0))


            c = MOI.addconstraint!(m, MOI.VectorAffineFunction([1,1,2,3,3], [x,s,y,x,z], [1.0,-1.0,1.0,1.0,1.0], [4.0,3.0,-12.0]), MOI.Zero(3))

            vy = MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[y],[1.0],[0.0]), Nonpositive(1))
            vz = MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[z],[1.0],[0.0]), Nonnegative(1))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zero}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonpositive}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonnegative}()) == 1


            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ -82 atol=ε

            @test MOI.cangetattribute(m, MOI.VariablePrimal(), x)
            @test MOI.getattribute(m, MOI.VariablePrimal(), x) ≈ -4 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), y) ≈ -3 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), z) ≈ 16 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), s) ≈ 0 atol=ε

            @test MOI.cangetattribute(m, MOI.ConstraintDual(), c)
            @test MOI.getattribute(m, MOI.ConstraintDual(), c) ≈ [-7, -2, 4] atol=ε

            # TODO var dual and con primal

        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Nonpositive),(MOI.VectorAffineFunction{Float64},MOI.Nonnegative)])
        @testset "LIN3 - infeasible" begin
            # Problem LIN3 - Infeasible LP
            # min  0
            # s.t. x ≥ 1
            #      x ≤ -1
            # in conic form:
            # min 0
            # s.t. -1 + x ∈ R₊
            #       1 + x ∈ R₋

            m = MOI.SolverInstance(solver)

            x = MOI.addvariable!(m)

            MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[x],[1.0],[-1.0]), MOI.Nonnegative(1))
            MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[x],[1.0],[1.0]), MOI.Nonpositve(1))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonnegative}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonpositive}()) == 1

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test !MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.InfeasibilityCertificate

            # TODO test dual feasibility and objective sign
        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Nonnegative),(MOI.VectorVariablewiseFunction,MOI.Nonpositive)])
        @testset "LIN4 - infeasible" begin
            # Problem LIN4 - Infeasible LP
            # min  0
            # s.t. x ≥ 1
            #      x ≤ 0
            # in conic form:
            # min 0
            # s.t. -1 + x ∈ R₊
            #           x ∈ R₋

            m = MOI.SolverInstance(solver)

            x = MOI.addvariable!(m)

            MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[x],[1.0],[-1.0]), MOI.Nonnegative(1))
            MOI.addconstraint!(m, MOI.VectorVariablewiseFunction([x]), MOI.Nonpositve(1))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonnegative}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorVariablewiseFunction,MOI.Nonpositive}()) == 1

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test !MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.InfeasibilityCertificate

            # TODO test dual feasibility and objective sign
        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Zeros),(MOI.VectorVariablewiseFunction,MOI.SecondOrderCone)])
        @testset "SOC1" begin
            # Problem SOC1
            # max 0x + 1y + 1z
            #  st  x            == 1
            #      x >= ||(y,z)||

            m = MOI.SolverInstance(solver)

            x,y,z = MOI.addvariables!(m, 3)

            MOI.setobjective!(m, MOI.MaxSense, MOI.ScalarAffineFunction([y,z],[-1.0,-1.0],0.0))

            ceq = MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[x],[1.0],[-1.0]), MOI.Zeros(1))
            csoc = MOI.addconstraint!(m, MOI.VectorVariablewiseFunction([x,y,z]), MOI.SecondOrderCone(3))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zeros}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorVariablewiseFunction,MOI.SecondOrderCone}()) == 1
            loc = MOI.getattribute(m, MOI.ListOfConstraints())
            @test length(loc) == 2
            @test (MOI.VectorAffineFunction{Float64},MOI.Zeros) in loc
            @test (MOI.VectorVariablewiseFunction,MOI.SecondOrderCone) in loc

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ sqrt(2) atol=ε

            @test MOI.cangetattribute(m, MOI.VariablePrimal(), x)
            @test MOI.getattribute(m, MOI.VariablePrimal(), x) ≈ 1 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), y) ≈ 1/sqrt(2) atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), z) ≈ 1/sqrt(2) atol=ε

            @test MOI.cangetattribute(m, MOI.ConstraintDual(), ceq)
            @test MOI.getattribute(m, MOI.ConstraintDual(), ceq) ≈ [sqrt(2)] atol=ε
            @test MOI.cangetattribute(m, MOI.ConstraintDual(), csoc)
            @test MOI.getattribute(m, MOI.ConstraintDual(), csoc) ≈ [sqrt(2), -1.0, -1.0] atol=ε

            # TODO con primal
        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Zeros),(MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone)])
        @testset "SOC1A" begin
            # Problem SOC1A
            # max 0x + 1y + 1z
            #  st  x            == 1
            #      x >= ||(y,z)||
            # same as SOC1 but with soc constraint enforced with VectorAffineFunction

            m = MOI.SolverInstance(solver)

            x,y,z = MOI.addvariables!(m, 3)

            MOI.setobjective!(m, MOI.MaxSense, MOI.ScalarAffineFunction([y,z],[-1.0,-1.0],0.0))

            ceq = MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[x],[1.0],[-1.0]), MOI.Zeros(1))
            csoc = MOI.addconstraint!(m, MOI.VectorAffineFunction([1,2,3],[x,y,z],ones(3),zeros(3)), MOI.SecondOrderCone(3))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zeros}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone}()) == 1

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ sqrt(2) atol=ε

            @test MOI.cangetattribute(m, MOI.VariablePrimal(), x)
            @test MOI.getattribute(m, MOI.VariablePrimal(), x) ≈ 1 atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), y) ≈ 1/sqrt(2) atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), z) ≈ 1/sqrt(2) atol=ε

            @test MOI.cangetattribute(m, MOI.ConstraintDual(), ceq)
            @test MOI.getattribute(m, MOI.ConstraintDual(), ceq) ≈ [sqrt(2)] atol=ε
            @test MOI.cangetattribute(m, MOI.ConstraintDual(), csoc)
            @test MOI.getattribute(m, MOI.ConstraintDual(), csoc) ≈ [sqrt(2), -1.0, -1.0] atol=ε

            # TODO con primal
        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Zeros),(MOI.VectorAffineFunction{Float64},MOI.Nonnegative),(MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone)])
        @testset "SOC2" begin
            # Problem SOC2
            # min  x
            # s.t. y ≥ 1/√2
            #      x² + y² ≤ 1
            # in conic form:
            # min  x
            # s.t.  -1/√2 + y ∈ R₊
            #        1 - t ∈ {0}
            #      (t,x,y) ∈ SOC₃

            m = MOI.SolverInstance(solver)

            x,y,t = MOI.addvariables!(m, 2)

            MOI.setobjective!(m, MinSense, MOI.ScalarAffineExpression([x],[1.0],0.0))

            MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[y],[1.0],[-1/sqrt(2)]), MOI.Nonnegative(1))
            MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[t],[-1.0],[1.0]), MOI.Zeros(1))
            MOI.addconstraint!(m, MOI.VectorAffineFunction([1,2,3],[t,x,y],ones(3),zeros(3)), MOI.SecondOrderCone(3))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonnegative}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zeros}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone}()) == 1

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ -1/sqrt(2) atol=ε

            @test MOI.getattribute(m, MOI.VariablePrimal(), x) ≈ -1/sqrt(2) atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), y) ≈ 1/sqrt(2) atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), t) ≈ 1 atol=ε

            # TODO constraint primal and duals
        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Zeros),(MOI.VectorAffineFunction{Float64},MOI.Nonpositive),(MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone)])
        @testset "SOC2A" begin
            # Problem SOC2A
            # Same as SOC2 but with nonpostive instead of nonnegative
            # min  x
            # s.t.  1/√2 - y ∈ R₋
            #        1 - t ∈ {0}
            #      (t,x,y) ∈ SOC₃

            m = MOI.SolverInstance(solver)

            x,y,t = MOI.addvariables!(m, 2)

            MOI.setobjective!(m, MOI.MinSense, MOI.ScalarAffineExpression([x],[1.0],0.0))

            MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[y],[-1.0],[1/sqrt(2)]), MOI.Nonpositive(1))
            MOI.addconstraint!(m, MOI.VectorAffineFunction([1],[t],[-1.0],[1.0]), MOI.Zeros(1))
            MOI.addconstraint!(m, MOI.VectorAffineFunction([1,2,3],[t,x,y],ones(3),zeros9(3)), MOI.SecondOrderCone(3))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonpositive}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Zeros}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone}()) == 1

            MOI.optimize!(m)

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.getattribute(m, MOI.PrimalStatus()) == MOI.FeasiblePoint
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.FeasiblePoint

            @test MOI.cangetattribute(m, MOI.ObjectiveValue())
            @test MOI.getattribute(m, MOI.ObjectiveValue()) ≈ -1/sqrt(2) atol=ε

            @test MOI.getattribute(m, MOI.VariablePrimal(), x) ≈ -1/sqrt(2) atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), y) ≈ 1/sqrt(2) atol=ε
            @test MOI.getattribute(m, MOI.VariablePrimal(), t) ≈ 1 atol=ε

            # TODO constraint primal and duals
        end
    end

    if MOI.supportsproblem(solver, MOI.ScalarAffineFunction, [(MOI.VectorAffineFunction{Float64},MOI.Nonnegative),(MOI.VectorAffineFunction{Float64},MOI.Nonpositive),(MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone)])
        @testset "SOC3 - infeasible" begin
            # Problem SOC3 - Infeasible
            # min 0
            # s.t. y ≥ 2
            #      x ≤ 1
            #      |y| ≤ x
            # in conic form:
            # min 0
            # s.t. -2 + y ∈ R₊
            #      -1 + x ∈ R₋
            #       (x,y) ∈ SOC₂

            m = MOI.SolverInstance(solver)

            x,y = MOI.addvariables!(m, 2)

            MOI.addconstraint!(m, VectorAffineFunction([1],[y],[1.0],[-2.0]), MOI.Nonnegative(1))
            MOI.addconstraint!(m, VectorAffineFunction([1],[x],[1.0],[-1.0]), MOI.Nonpositive(1))
            MOI.addconstraint!(m, VectorAffineFunction([1,2],[x,y],ones(2),zeros(2)), MOI.SecondOrderCone(2))

            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonnegative}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.Nonpositive}()) == 1
            @test MOI.getattribute(m, MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64},MOI.SecondOrderCone}()) == 1

            @test MOI.cangetattribute(m, MOI.TerminationStatus())
            @test MOI.getattribute(m, MOI.TerminationStatus()) == MOI.Success

            @test !MOI.cangetattribute(m, MOI.PrimalStatus())
            @test MOI.cangetattribute(m, MOI.DualStatus())
            @test MOI.getattribute(m, MOI.DualStatus()) == MOI.InfeasibilityCertificate

            # TODO test dual feasibility and objective sign
        end
    end

    # TODO more models
end
