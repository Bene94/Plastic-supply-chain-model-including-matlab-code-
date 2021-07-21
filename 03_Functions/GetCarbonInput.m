function [CarbonInputShares] = GetCarbonInput(s,A_matrix,row,column)

% This script calculates the carbon input shares to the life cycle of 14
% plastic materials.

%% Rescale A_matrix to carbon contents only

A = A_matrix;
carbon_contents = full(sparse(ones(height(row),1),row.row,row.carbon_content)); % generate carbon content

carbon_contents(isnan(carbon_contents)) = 0;

A_scaled = A.*repmat(s',size(A,1),1).*...
    repmat(carbon_contents',1,size(A,2)); % matrix with only the carbon contents and scaled to s (scaling vector)


%% Biomass input
BiomassFlowsNames = {...
'wood pellets';...
'wood chips';...
'miscanthus';...
'bark chips';...
};

Col_Biomass = column.column(contains(column.name,"correction of bio"));
Rows_Biomass = row.row(contains(row.name,BiomassFlowsNames));

BiomassInput = sum(sum(A_scaled(Rows_Biomass,Col_Biomass),1));

%% CO2 input
Col_CO2 = column.column(contains(column.name,"compression to 100bar"));
Rows_CO2 = row.row(contains(row.name,'carbon dioxide (100bar)'));

CO2Input = sum(sum(A_scaled(Rows_CO2,Col_CO2),1));

%% recycling input
Rows_Waste = row.row(contains(row.name,'waste')|contains(row.name,'DSD spec'));
Col_Recycling = column.column(contains(column.name,"mechanical recycling")|...
    contains(column.name,"sorting of")|...
    contains(column.name,"pyrolysis of ")); % identify landfill processes

WasteInput = sum(sum(A_scaled(Rows_Waste,Col_Recycling),1));

%% Generate Output
shares = [BiomassInput,CO2Input,-WasteInput]';
shares = shares/sum(shares);
name = ["biomass";"CO2";"Plastic waste"];
CarbonInputShares = table(name,shares);

