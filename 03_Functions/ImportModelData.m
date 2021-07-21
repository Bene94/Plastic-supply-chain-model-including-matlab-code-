%% Import from PlasticSupplyChainModel.xlsx

Excelfilepath = [pwd,'\01_Input\PlasticSupplyChainModel.xlsx'];

%% Import A matrix
opts = spreadsheetImportOptions("NumVariables", 3);

opts.Sheet = "A";
opts.DataRange = "A2:C2046";

opts.VariableNames = ["row", "column", "value"];
opts.VariableTypes = ["double", "double", "double"];

A = readtable(Excelfilepath, opts, "UseExcel", false);

%% Import objective (Q*B for CO2-equiv, IPCC 2013 method)
opts = spreadsheetImportOptions("NumVariables", 2);

opts.Sheet = "obj";
opts.DataRange = "A2:B412";

opts.VariableNames = ["column", "value"];
opts.VariableTypes = ["double", "double"];

obj = readtable(Excelfilepath, opts, "UseExcel", false);

%% Import y (final demand)
opts = spreadsheetImportOptions("NumVariables", 5);

opts.Sheet = "y";
opts.DataRange = "A2:E71";

opts.VariableNames = ["row", "year", "value_kg", "flow", "unit"];
opts.VariableTypes = ["double", "double", "double", "categorical", "categorical"];

opts = setvaropts(opts, ["flow", "unit"], "EmptyFieldRule", "auto");

y = readtable(Excelfilepath, opts, "UseExcel", false);

%% Import row meta data
opts = spreadsheetImportOptions("NumVariables", 4);

opts.Sheet = "row";
opts.DataRange = "A2:D171";

opts.VariableNames = ["row", "name", "unit", "carbon_content"];
opts.VariableTypes = ["double", "string", "categorical", "double"];

opts = setvaropts(opts, "name", "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["name", "unit"], "EmptyFieldRule", "auto");

row = readtable(Excelfilepath, opts, "UseExcel", false);

%% Import column meta data
opts = spreadsheetImportOptions("NumVariables", 4);

opts.Sheet = "column";
opts.DataRange = "A2:D427";

opts.VariableNames = ["column", "name", "mainflow", "license_needed"];
opts.VariableTypes = ["double", "string", "string", "categorical"];

opts = setvaropts(opts, ["name", "mainflow"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["name", "mainflow", "license_needed"], "EmptyFieldRule", "auto");

column = readtable(Excelfilepath, opts, "UseExcel", false);

%% Import years
opts = spreadsheetImportOptions("NumVariables", 2);

opts.Sheet = "year";
opts.DataRange = "A2:B3";

opts.VariableNames = ["year", "Description"];
opts.VariableTypes = ["double", "double"];

year = readtable(Excelfilepath, opts, "UseExcel", false);

%% clear varibales
clear opts Workbook
