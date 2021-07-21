%% Code to generate results from the chemical and plastics industry model

% Please contact Meys, Raoul <Raoul.Meys@ltt.rwth-aachen.de> or Bardow André
% <abardow@ethz.ch> for further details, questions or comments.
% Note that the model cannot be supplied with all data, since
% licensing agreements with IHS Markit have to be in place in some cases.
% Contact IHS Markit via
% https://ihsmarkit.com/products/chemical-technology-pep-index.html 

% clear workspace and command window
clc
clear

% add matlab subroutines
addpath(genpath([pwd,'\03_Functions\']));


%% include model data
% The function ImportModelData.m is a simple script that imports all data
% included in the PlasticSupplyChainModel.xlsx

run('ImportModelData.m');

% check if data is complete

if any(isnan(A.column))
    
    disp('Model is not complete. Script is terminated. Please check data and licensing agreements.');
    return
    
end

%% generate matrices
% This part of the script generates the matrices from the Excel input "PlasticSupplyChainModel.xlsx". The
% matrices include:
% The technology matrix A (A_matrix) that includes all mass and energy flows.
% The objective function that includes the CO2-equiv emissions according to
% the IPCC 2013 methodology.
% The final demand for 14 large volume plastic productsio in 2050.
% Additionally the file includes the respective meta data about rows,
% columns and the years (row, column, year).

A_matrix = full(sparse(A.row,A.column,A.value)); % generate technology matrix A
objective = full(sparse(ones(height(obj),1),obj.column,obj.value)); % generate objective function
FinalDemand2050 = full(sparse(y.row(y.year == 2),ones(height(y(y.year == 2,:)),1),y.value_kg(y.year == 2))); % generate final demand in 2050

%% correct size of final demand to same size as A
% The final demand has fewer lines, which is why it has to be corrected to
% the size of the technology matrix A in order to be usable in the MATLAB
% optimization framework.

if size(FinalDemand2050,1) < size(A_matrix,1)
    
    FinalDemand2050 = [FinalDemand2050;zeros(size(A_matrix,1)-size(FinalDemand2050,1),1)];
    
end


%% load a pathway for optimization
% Here the pathway can be choosen from from fossil_industry, recycling_pathway, CCU_pathway,
% biomass_pathway, circular_carbon_pathway.
% To do so, copy the pathway name into the following line. The pathway
% defines which rechnologies are included in the scenario or not.
ChosenPathway = 'circular_carbon_pathway';

pathway = ImportPathway([pwd,'\01_input\Pathways.xlsx'], string(ChosenPathway));

% transfer pathway to matrix format
pathway_matrix = full(sparse(ones(height(pathway),1),pathway.col,pathway.allowed));

% forbid pathway processes
pathway_constraint = 0; % the zero indicates that the processes included in pathway_matrix cannot be used.


%% set boundary for landfilling amount
% Here a fixed constraint for landfilling is included. This fixed
% constraints equals 6% of the global plastic waste volume.

% calculate overall waste amount
WasteInput = sum(FinalDemand2050(FinalDemand2050<0)); 

% calculate 6% of overall waste amount
Constraint_6_percentage_landfill = 0.06*WasteInput; 

% get landfill processes
Col_Landfill = column.column(contains(column.name,"landfill"));
 
% get landfilling constraints
landfilling_constraint = zeros(1,size(A_matrix,2)); 
landfilling_constraint(Col_Landfill) = -1;

%% prepare optimization
% In this part the optimization constraints are generated.

% combine A_matrix, pathway and landfilling_constraint
A_eq = [landfilling_constraint;pathway_matrix;A_matrix];
% The equality constraint includes the landfill constraint, the pathway
% constraint that represent the technologies that are allowed in optimization
% and the technology matrix A.

% combine FinalDemand2050, pathway_constraint and Constraint_6_percentage_landfill
b_eq = [Constraint_6_percentage_landfill;pathway_constraint;FinalDemand2050];
% The equality constraints include the 6% landfill, the allowed pathway and
% the final demand of 14 platic materials.

% set electricity impact to specific value
Col_Electricity = column.column(contains(column.name,"market group for electricity (ecoinvent)"));
% The only external parameter of the model is the electricity supply. The
% electricity supply carbon footprint has to be defined for each scenario.

objective(Col_Electricity) = 0.007/3.6; % in MJ
% Set default value for global averge --> 0.202045370943741 kg CO2 per MJ 
% Set default value for wind-based electricity --> 0.007/3.6 MJ (0.007 kg per kWh)

%% optimization
% see documentation in function

[s, obj_result, exitflag] =...
    main_single_optimization(objective,...
    A_eq, b_eq, [], [], [], []); % see also comments in the matlab function.

%% calculate carbon inputs to plastic production
% see documentation in function

[CarbonInputShares] = GetCarbonInput(s,A_matrix,row,column);

%% multicriteria optimization
% Here, a multiobjective optimization is generated to derive minimal energy
% demands while reaching net-zero emission plastics.

% First: define obj_biomass_MJ (biomass amount in MJ)

Col_Biomass = column.column(contains(column.name,"correction of bio"));

LowerHeatingValues = [  8.6586;... % wood pellets
                        8.9797;... % wood chips
                        15.7195;... % miscanthus
                        15.8438]; % bark chips
                    
obj_biomass_MJ = zeros(size(objective));
obj_biomass_MJ(Col_Biomass) = LowerHeatingValues;

% define obj_elec_MJ (electricity amount in MJ)

obj_elec_MJ = zeros(size(objective));
obj_elec_MJ(Col_Electricity) = 1;

% Second: define multiobjective optimization problem

obj_1 = [objective];
obj_2 = [obj_biomass_MJ];
obj_3 = [obj_elec_MJ];

const_1 = 0; % Gt CO2-equiv equal to 0 to achieve net-zero emission plastics

steps = 500; % include steps for multiobjective optimization

[s_MultiObjective, ~ ] =... % see documentation in function.
    MultiobjectiveOptimization(...
    A_eq, b_eq, [], [], [], [],... 
    obj_1, obj_2, obj_3,... % objective 1 is constraints by obj_1 = const_1
    const_1,...
    steps); 

Electricity_PWh = (obj_3*s_MultiObjective/3.6e12)'; % calculate electricity demand in PWh
Biomass_EJ = (obj_2*s_MultiObjective/1e12)'; % calculate biomass demand in MJ

OutputMultiOpt = table(Electricity_PWh, Biomass_EJ); % generate output for saving

%% save results

stamp = datestr(now,30);
stamp = [stamp,'_','results'];
mkdir([pwd,'\02_Output\','\',stamp,'\']);

path_output_folder_full = [pwd,'\02_Output\','\',stamp]; % generate folder for outputs of the run

xlswrite([path_output_folder_full,...
    '\','S.xlsx'],...
    [(1:length(s))',s]); % safe the scaling vector

xlswrite([path_output_folder_full,...
    '\','EmissionResults.xlsx'],...
    [{'Gt CO2-equiv for'};...
    {['the ',ChosenPathway,', with a electricity grid intensity of ']};...
    {[num2str(objective(Col_Electricity)*1000),'g CO2 per MJ:']};...
    {obj_result/1e12}]); % safe the output greenhouse gas emission with the respective meta data.

writetable(CarbonInputShares,[path_output_folder_full,...
    '\','CarbonInputShares.xlsx']); % safe the scaling vector

writetable(OutputMultiOpt,[path_output_folder_full,...
    '\','OutputMultiOpt.xlsx']); % safe the scaling vector

%% remove paths

rmpath(genpath([pwd,'\03_Functions\'])); % remove functions from known paths