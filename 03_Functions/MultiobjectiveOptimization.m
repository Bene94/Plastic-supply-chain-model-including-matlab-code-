function [s_ap2, obj_2_values ] =... 
    MultiobjectiveOptimization(...
    A_eq, b_eq, A_ineq, b_ineq, lb, ub,... % define general constraints
    obj_1, obj_2, obj_3,... % objective 1 is constraints by obj_1 = const_1
    const_1,...
    steps) % steps define the granularity of optimization

% enable empty constraints and steps
if isempty(const_1)
    const_1 = 0;
end

if isempty(steps)
    steps = 50;
end

% include constraint of objective 1

A_eq = [ A_eq ; obj_1];
b_eq = [ b_eq ; const_1];

%% get anchor point of objective 2

% optimize
[~, fval_ap_2 , ~] =...
    main_single_optimization(obj_3,...
    A_eq, b_eq, A_ineq, b_ineq, lb, ub);

% include constraint of objective 3, optimize objective 2

A_ineq_ap_2 = [ A_ineq ; obj_3];
b_ineq_ap_2 = [ b_ineq ; fval_ap_2];

% optimize
[s_ap2, ~ , ~] =...
    main_single_optimization(obj_2,...
    A_eq, b_eq, A_ineq_ap_2, b_ineq_ap_2, lb, ub);

ap_2(1,1) = const_1;
ap_2(2,1) = obj_2*s_ap2;
ap_2(3,1) = obj_3*s_ap2;


%% get anchor point of objective 3

% optimize
[~, fval_ap_3 , ~] =...
    main_single_optimization(obj_2,...
   A_eq, b_eq, A_ineq, b_ineq, lb, ub);

% include constraint of objective 2, optimize objective 3
A_ineq_ap_3 = [A_ineq ; obj_2];
b_ineq_ap_3 = [b_ineq ; fval_ap_3];

% optimize
[s_ap3, ~ , ~] =...
    main_single_optimization(obj_3,...
    A_eq, b_eq, A_ineq_ap_3, b_ineq_ap_3, lb, ub);

ap_3(1,1) = const_1;
ap_3(2,1) = obj_2*s_ap3;
ap_3(3,1) = obj_3*s_ap3;

%% check anchor point
if    isequal(ap_3(2,1),ap_2(2,1)) &&...
      isequal(ap_3(3,1),ap_2(3,1))
      
  
  disp('Only one anchor point ==> pareto point, no parto front.')
  obj_2_values = ap_3(2,1);
  obj_3_values = ap_3(3,1);

  return
  
end

%% multiobjective optimization between anchor points

% variation of two objectives

variation_objective_3 = sort([ap_2(3,1);ap_3(3,1)]);

var_objective_3 = (variation_objective_3(2)-variation_objective_3(1))/steps;

steps_objective_3 = variation_objective_3(1) : var_objective_3 : variation_objective_3(2);

%% epsilon constraint for objective 2
counter = 1;

n = size(ap_2,1);
m = size(steps_objective_3,2);

obj_2_values = zeros(n,m);

for i = 1:length(steps_objective_3)
    
    A_ineq_ap_2 = [ A_ineq ; obj_3 ];
    b_ineq_ap_2 = [ b_ineq ; steps_objective_3(i) ];
    
    [ s, fval_obj_2 , ~] =...
        main_single_optimization(obj_2,...
        A_eq, b_eq, A_ineq_ap_2, b_ineq_ap_2, [], []);
    
    if isempty(fval_obj_2) && steps_objective_3(i)<0
        
        A_ineq_ap_2 = [ A_ineq ;  obj_3];
        b_ineq_ap_2 = [ b_ineq ;  steps_objective_3(i)*0.9998];
    
        [ s, fval_obj_2 , ~] =...
        main_single_optimization(obj_2,...
        A_eq, b_eq, A_ineq_ap_2, b_ineq_ap_2, [], []);
        
    end
    
    if isempty(fval_obj_2) && steps_objective_3(i)>0
        
        A_ineq_ap_2 = [ A_ineq ; obj_3];
        b_ineq_ap_2 = [ b_ineq ;  steps_objective_3(i)*1.0002];
    
        [ s, fval_obj_2 , ~] =...
        main_single_optimization(obj_2,...
        A_eq, b_eq, A_ineq_ap_2, b_ineq_ap_2, [], []);
        
    end
    
    if isempty(fval_obj_2)
        
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        disp('NO SOLUTION FOUND');
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        continue
        
    end
    
    s_ap2(:,i) = s;
    
    obj_2_values(1,counter) = obj_1*s_ap2(:,i);
    obj_2_values(2,counter) = obj_2*s_ap2(:,i);
    obj_2_values(3,counter) = obj_3*s_ap2(:,i);
    
    counter = counter + 1;
    
end

end