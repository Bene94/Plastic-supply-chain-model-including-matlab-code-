function pathway = ImportPathway(workbookFile, sheetName)

dataLines = [2, 427];

opts = spreadsheetImportOptions("NumVariables", 2);

opts.Sheet = sheetName;
opts.DataRange = "A" + dataLines(1, 1) + ":B" + dataLines(1, 2);

opts.VariableNames = ["col", "allowed"];
opts.VariableTypes = ["double", "double"];

pathway = readtable(workbookFile, opts, "UseExcel", false);

end