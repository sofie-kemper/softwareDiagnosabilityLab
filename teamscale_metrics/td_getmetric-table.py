from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import requests
import os
import csv

from teamscale_client import TeamscaleClient
from teamscale_client.constants import ReportFormats

TEAMSCALE_URL = "http://localhost:8080"
USERNAME = "admin"
ACCESS_TOKEN = "F6K3FvEInVLlVMQRgIJ69oUeEIRPsiCE"
OUTPUT_FILE_NAME = "staticMetrics.csv"
CSV_SEPERATOR_CHAR = ','
OUTPUT_DIR = "C:\\study\\SWDiag\\sharedFolder_UbuntuVM\\Metrics_Results"
# ----------------------- CHANGE THIS BLOCK FOR EACH PROJECT ----------------
PROJECT_ID = "Closure"
VERSIONS = 133
RELATIVE_PATH = "src/com/google"
NEW_RELATIVE_PATH = "src/com/google/javascript"
OLD_RELATIVE_PATH = "src/com/google"
VERSION_NEW_PATH_FROM = 79
VERSION_NEW_PATH_TILL = 106
#RELATIVE_PATH = "src/org/mockito"
#RELATIVE_PATH = "org/mockito"
# ---------------------- CHANGE THIS BLOCK FOR EACH PROJECT -----------------
metricNamesIDsMapping = { "Files":"Files",
"Lines of Code":"LOC",
"Source Lines of Code":"SLOC",
"Number of Findings":"CF",
"Clone Coverage":"F-CLC",
"Number of Findings in F-BP":"F-BP",
"Number of Findings in F-CL":"F-CL",
"Number of Findings in F-CF":"F-CF",
"Number of Findings in F-ND": "F-ND",
"Number of Findings in F-UC":"F-UC",
"Number of Findings in F-FS":"F-FS",
"Number of Findings in F-MBB": "F-MBB", 
"Number of Findings in F-RT":"F-RT",
"Number of Findings in F-MC":"F-MC",
"Number of Findings in F-NP":"F-NP",
"Number of Findings in F-UVP":"F-UVP",
"Number of Findings in F-EH":"F-EH",
"Number of Findings in F-PCL":"F-PCL",
"Number of Findings in F-ML":"F-ML",
"Maximum Cyclomatic Complexity":"MAXCC"
}
outputFileHeader = ["id","Files","LOC","SLOC",
"F-HFS","F-MFS","F-LFS","F-PHFS","F-PMFS","F-PLFS",
"F-HND","F-MND","F-LND","F-PHND","F-PMND","F-PLND",
"MAXCC","HCC","MCC","LCC","PHCC","PMCC","PLCC",
"CF", "CF-D",
"F-CLC",
"F-BP", "F-BP-D",
"F-CF", "F-CF-D",
"F-CL", "F-CL-D",
"F-EH", "F-EH-D",
"F-FS", "F-FS-D",
"F-MBB", "F-MBB-D",
"F-MC", "F-MC-D",
"F-ML", "F-PML",
"F-ND", "F-ND-D",
"F-NP", "F-NP-D",
"F-PCL", "F-PCL-D",
"F-RT", "F-RT-D",
"F-UC", "F-UC-D",
"F-UVP","F-UVP-D"]

numberOfMetrics = 29

def check_metricValues_contains_all_metrics(metricValues):
    if(not (len(metricValues) == numberOfMetrics)):
        print("WARNING: ", numberOfMetrics, " metrics are expected but values for only ", len(metricValues), " were extracted")
        return 0
    return 1
    
def extract_values_from_JSON_resp(json):
    metricValues =  dict()
    metricsList = []
    for metricTableEntry in json:
        if (metricTableEntry['relativePath'] == RELATIVE_PATH):
#            print("DEBUG: found right metricTableEntry with path ", RELATIVE_PATH)
            metricsList = metricTableEntry['metrics']
            break
    if (metricsList == []):
        print("ERROR: Couldn't find metrics list or right metric table entry for current version")
        return metricValues
    for metric in metricsList:
        if (metric['name'] == "Nesting Depth Assessment"):
            nestingDepthValueDict = metric['value']
            nestingDepthValuesList = nestingDepthValueDict['mapping']
            metricValues['F-HND'] = nestingDepthValuesList[0]
            metricValues['F-MND'] = nestingDepthValuesList[2]
            metricValues['F-LND'] = nestingDepthValuesList[3]
            if (nestingDepthValuesList[1] != 0 or nestingDepthValuesList[4] != 0 or nestingDepthValuesList[5] != 0):
                print("WARNING: Nesting Depth Assessment value 1, 4 or 5 was not 0")
        elif (metric['name'] == "File Size Assessment"):
            fileSizeValueDict = metric['value']
            fileSizeValuesList = fileSizeValueDict['mapping']
            metricValues['F-HFS'] = fileSizeValuesList[0]
            metricValues['F-MFS'] = fileSizeValuesList[2]
            metricValues['F-LFS'] = fileSizeValuesList[3]
            if (fileSizeValuesList[1] != 0 or fileSizeValuesList[4] != 0 or fileSizeValuesList[5] != 0):
                print("WARNING: File Size Assessment value 1, 4 or 5 was not 0")
        elif (metric['name'] == "Cyclomatic Complexity Assessment"):
            ccValueDict = metric['value']
            ccValuesList = ccValueDict['mapping']
            metricValues['HCC'] = ccValuesList[0]
            metricValues['MCC'] = ccValuesList[2]
            metricValues['LCC'] = ccValuesList[3]
            if (fileSizeValuesList[1] != 0 or fileSizeValuesList[4] != 0 or fileSizeValuesList[5] != 0):
                print("WARNING: Cyclomatic Complexity Assessment value 1, 4 or 5 was not 0")
        else:
            if (metric['name'] in metricNamesIDsMapping):
                metricValues[metricNamesIDsMapping[metric['name']]] = float(metric['stringValue'])
    return metricValues

def create_output_csv_file():
    filePath = OUTPUT_DIR + "\\" + PROJECT_ID + "\\" + OUTPUT_FILE_NAME
    outputFile = open(filePath, "w", newline='')
    print("DEBUG: Writing values to output file: ", filePath)
    return outputFile

def write_metric_values_to_output_file(f, valuesDict):
    csvWriter = csv.writer(f, delimiter=CSV_SEPERATOR_CHAR, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    print("DEBUG: Writing header...")
    csvWriter.writerow(valuesDict[0])
    for lineNumber in range(1,VERSIONS+1):
        print("DEBUG: Writing line for Version ", lineNumber)
        row = [PROJECT_ID + "_" + str(lineNumber)]
        row.extend(valuesDict[lineNumber])
        csvWriter.writerow(row)
 
def calculate_proportion_and_density_values(metricValuesDict):
    methodsCount = metricValuesDict['F-HND'] + metricValuesDict['F-MND'] + metricValuesDict['F-LND']
    sloc = metricValuesDict['SLOC']
    metricValuesDict['F-PHND'] = metricValuesDict['F-HND'] / methodsCount
    metricValuesDict['F-PMND'] = metricValuesDict['F-MND'] / methodsCount
    metricValuesDict['F-PLND'] = metricValuesDict['F-LND'] / methodsCount
    metricValuesDict['F-PML'] = metricValuesDict['F-ML'] / methodsCount
    metricValuesDict['PHCC'] = metricValuesDict['HCC'] / methodsCount
    metricValuesDict['PMCC'] = metricValuesDict['MCC'] / methodsCount
    metricValuesDict['PLCC'] = metricValuesDict['LCC'] / methodsCount
    metricValuesDict['F-PHFS'] = metricValuesDict['F-HFS'] / sloc
    metricValuesDict['F-PMFS'] = metricValuesDict['F-MFS'] / sloc
    metricValuesDict['F-PLFS'] = metricValuesDict['F-LFS'] / sloc
    metricValuesDict['CF-D'] = 1000 * metricValuesDict['CF'] / sloc
    metricValuesDict['F-BP-D'] = 1000 * metricValuesDict['F-BP'] / sloc
    metricValuesDict['F-CF-D'] = 1000 * metricValuesDict['F-CF'] / sloc
    metricValuesDict['F-CL-D'] = 1000 * metricValuesDict['F-CL'] / sloc
    metricValuesDict['F-EH-D'] = 1000 * metricValuesDict['F-EH'] / sloc
    metricValuesDict['F-FS-D'] = 1000 * metricValuesDict['F-FS'] / sloc
    metricValuesDict['F-MBB-D'] = 1000 * metricValuesDict['F-MBB'] / sloc
    metricValuesDict['F-ND-D'] = 1000 * metricValuesDict['F-ND'] / sloc
    metricValuesDict['F-NP-D'] = 1000 * metricValuesDict['F-NP'] / sloc
    metricValuesDict['F-PCL-D'] = 1000 * metricValuesDict['F-PCL'] / sloc
    metricValuesDict['F-RT-D'] = 1000 * metricValuesDict['F-RT'] / sloc
    metricValuesDict['F-UC-D'] = 1000 * metricValuesDict['F-UC'] / sloc
    metricValuesDict['F-MC-D'] = 1000 * metricValuesDict['F-MC'] / sloc
    metricValuesDict['F-UVP-D'] = 1000 * metricValuesDict['F-UVP'] / sloc

def get_ordered_metric_values(metricValuesDict):
    valuesList = []
    for element in outputFileHeader:
        if (element == "id"):
            continue
        valuesList.append(metricValuesDict[element])
    return valuesList

if __name__ == '__main__':
    print("Program Started, build REST Client...")
    client = TeamscaleClient(TEAMSCALE_URL, USERNAME, ACCESS_TOKEN, PROJECT_ID)
    firstVersionTimestamp = 1519862400000
    versionsInterval = 86400000
    metricValuesAllVersions = dict()
    metricValuesAllVersions[0] = outputFileHeader
    for versionCntr in range(0,VERSIONS):      # range end is excluding
        if (versionCntr+1 >= VERSION_NEW_PATH_FROM):
            RELATIVE_PATH = NEW_RELATIVE_PATH
        if (versionCntr+1 > VERSION_NEW_PATH_TILL):
            RELATIVE_PATH = OLD_RELATIVE_PATH
        versionTimestamp = firstVersionTimestamp + versionCntr * versionsInterval + 10000000
        print("DEBUG: Processing version ", versionCntr+1, "    timestamp of REST request: ", versionTimestamp)
        parameters = {"t":"default:" + str(versionTimestamp), "configurationName":"Teamscale Default"}
        r = client.get(TEAMSCALE_URL + "/p/" + PROJECT_ID.lower() + "/metric-table/", parameters)
        metricValues = extract_values_from_JSON_resp(r.json())
        if(check_metricValues_contains_all_metrics(metricValues)):
            calculate_proportion_and_density_values(metricValues)
            metricValuesAllVersions[versionCntr+1] = get_ordered_metric_values(metricValues)
        else:
            print("ERROR: Program won't export metric values for version " , versionCntr + 1)
            metricValuesAllVersions[versionCntr+1] = ["ERROR: not all metric values could be queried"]
    print("DEBUG: Finished extracting metric values")
    f = create_output_csv_file()
    write_metric_values_to_output_file(f, metricValuesAllVersions)
    f.close()
    CSV_SEPERATOR_CHAR = ';'
    OUTPUT_FILE_NAME = "staticMetrics_excel_format.csv"
    f = create_output_csv_file()
    write_metric_values_to_output_file(f, metricValuesAllVersions)
    f.close()
    print("Program Finished!")