function [s,fval,exitflag] =...
    main_single_optimization(objective,...
    A_eq, b_eq, A_ineq, b_ineq, lb, ub)

% This script transfer the respective input variables into an optimization
% problem and sets the options of the optimization problem.

%% check lower and upper bounds - set to default values
if isempty(ub)
    
    ub = ones(size(A_eq,2),1)*1e18;
    
end

if isempty(lb)
    
    lb = zeros(size(A_eq,2),1);
    
end


%% scale problem to increase solvability

volumes_variated = 0;

value_volumes_variated = 1e-10;

if sum(abs(b_eq)) > (1/value_volumes_variated)
    
    b_eq     = b_eq*value_volumes_variated;
    ub       = ub*value_volumes_variated;
    b_ineq   = b_ineq*value_volumes_variated;

    volumes_variated = 1;
   
end

%% optimize

options = optimoptions('linprog','Algorithm','dual-simplex','OptimalityTolerance',1e-8,'Display', 'final' );

[s,fval,exitflag] = linprog(objective, A_ineq, b_ineq , A_eq , b_eq , lb, ub , options);


%% rescale problem

s(s<1e-8) = 0; % delete computational uncertainties

if volumes_variated
    s       = s/value_volumes_variated;
    fval    = fval/value_volumes_variated;
end


end