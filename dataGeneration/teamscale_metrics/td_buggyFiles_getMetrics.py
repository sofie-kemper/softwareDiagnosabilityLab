from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals
from teamscale_client import TeamscaleClient
import copy
import csv

TEAMSCALE_URL = "http://localhost:8080"
USERNAME = "admin"
ACCESS_TOKEN = "F6K3FvEInVLlVMQRgIJ69oUeEIRPsiCE"
OUTPUT_FILE_NAME = "buggyFiles_staticMetrics.csv"
CSV_SEPERATOR_CHAR = ','
OUTPUT_DIR = "C:\\study\\SWDiag\\sharedFolder_UbuntuVM\\Metrics_Results"

# ----------------------- CHANGE THIS BLOCK FOR EACH PROJECT ----------------
PROJECT_ID = "Closure"
VERSIONS = 133
MC_PATH_PREFIX = "src/"
#MC_PATH_PREFIX = "src/main/java/"
VERSION_NEW_PREFIX = 999
#VERSION_NEW_PREFIX = 84    # if version > to this one use the new prefix
MC_PATH_NEW_PREFIX = "src/java/"
# ----------------------- CHANGE THIS BLOCK FOR EACH PROJECT ----------------
MC_PATH = "C:\\study\\SWDiag\\defects4j\\framework\\projects\\" + PROJECT_ID + "\\modified_classes\\"
MC_FILE_ENDING = ".src"

outputFileHeader = ["id", "BF-LOC","BF-SLOC",
"BF-F-HND","BF-F-MND","BF-F-LND","BF-F-PHND","BF-F-PMND","BF-F-PLND",
"BF-MAXCC","BF-HCC","BF-MCC","BF-LCC","BF-PHCC","BF-PMCC","BF-PLCC",
"BF-CF", "BF-CF-D",
"BF-F-CLC",
"BF-F-BP", "BF-F-BP-D",
"BF-F-CF", "BF-F-CF-D",
"BF-F-CL", "BF-F-CL-D",
"BF-F-EH", "BF-F-EH-D",
"BF-F-FS", "BF-F-FS-D",
"BF-F-MBB", "BF-F-MBB-D",
"BF-F-MC", "BF-F-MC-D",
"BF-F-ML", "BF-F-PML",
"BF-F-ND", "BF-F-ND-D",
"BF-F-NP", "BF-F-NP-D",
"BF-F-PCL", "BF-F-PCL-D",
"BF-F-RT", "BF-F-RT-D",
"BF-F-UC", "BF-F-UC-D",
"BF-F-UVP","BF-F-UVP-D"]
metricNamesIDsMapping = { "Lines of Code":"BF-LOC",
"Source Lines of Code":"BF-SLOC",
"Number of Findings":"BF-CF",
"Clone Coverage":"BF-F-CLC",
"Number of Findings in F-BP":"BF-F-BP",
"Number of Findings in F-CL":"BF-F-CL",
"Number of Findings in F-CF":"BF-F-CF",
"Number of Findings in F-ND": "BF-F-ND",
"Number of Findings in F-UC":"BF-F-UC",
"Number of Findings in F-FS":"BF-F-FS",
"Number of Findings in F-MBB": "BF-F-MBB", 
"Number of Findings in F-RT":"BF-F-RT",
"Number of Findings in F-MC":"BF-F-MC",
"Number of Findings in F-NP":"BF-F-NP",
"Number of Findings in F-UVP":"BF-F-UVP",
"Number of Findings in F-EH":"BF-F-EH",
"Number of Findings in F-PCL":"BF-F-PCL",
"Number of Findings in F-ML":"BF-F-ML",
"Maximum Cyclomatic Complexity":"BF-MAXCC"
}
numberOfMetrics = 25

def get_buggy_files(version):
    mcFile = open(MC_PATH + str(version) + MC_FILE_ENDING)
    lines = [line.rstrip('\n') for line in mcFile]
    filePaths = []
    for line in lines:
        linePath = line.replace('.', '/')
        linePath = MC_PATH_PREFIX + linePath + ".java"
        #print("DEBUG: Adding file to list: " + linePath)
        filePaths.append(linePath)
    return filePaths

def get_request(client, versionTimestamp, file):
    print("DEBUG: Perform get request for file ", file, " in version ", str(versionTimestamp))
    parameters = {"t":"default:" + str(versionTimestamp), "configurationName":"Teamscale Default"}
    print("TRACE: " + TEAMSCALE_URL + "/p/" + PROJECT_ID.lower() + "/metric-table/" + file)
    r = client.get(TEAMSCALE_URL + "/p/" + PROJECT_ID.lower() + "/metric-table/" + file, parameters)
    if (versionTimestamp == 1527130000000):
        print(r.json())
    return r.json()

def check_metricValues_contains_all_metrics(metricValues):
    if(not (len(metricValues) == numberOfMetrics)):
        print("ERROR: ", numberOfMetrics, " metrics are expected but values for only ", len(metricValues), " were extracted")
        return 0
    return 1

def calculate_proportion_and_density_values(metricValuesDict):
    methodsCount = metricValuesDict['BF-F-HND'] + metricValuesDict['BF-F-MND'] + metricValuesDict['BF-F-LND']
    sloc = metricValuesDict['BF-SLOC']
    metricValuesDict['BF-F-PHND'] = metricValuesDict['BF-F-HND'] / methodsCount
    metricValuesDict['BF-F-PMND'] = metricValuesDict['BF-F-MND'] / methodsCount
    metricValuesDict['BF-F-PLND'] = metricValuesDict['BF-F-LND'] / methodsCount
    metricValuesDict['BF-F-PML'] = metricValuesDict['BF-F-ML'] / methodsCount
    metricValuesDict['BF-PHCC'] = metricValuesDict['BF-HCC'] / methodsCount
    metricValuesDict['BF-PMCC'] = metricValuesDict['BF-MCC'] / methodsCount
    metricValuesDict['BF-PLCC'] = metricValuesDict['BF-LCC'] / methodsCount
    metricValuesDict['BF-CF-D'] = 1000 * metricValuesDict['BF-CF'] / sloc
    metricValuesDict['BF-F-BP-D'] = 1000 * metricValuesDict['BF-F-BP'] / sloc
    metricValuesDict['BF-F-CF-D'] = 1000 * metricValuesDict['BF-F-CF'] / sloc
    metricValuesDict['BF-F-CL-D'] = 1000 * metricValuesDict['BF-F-CL'] / sloc
    metricValuesDict['BF-F-EH-D'] = 1000 * metricValuesDict['BF-F-EH'] / sloc
    metricValuesDict['BF-F-FS-D'] = 1000 * metricValuesDict['BF-F-FS'] / sloc
    metricValuesDict['BF-F-MBB-D'] = 1000 * metricValuesDict['BF-F-MBB'] / sloc
    metricValuesDict['BF-F-ND-D'] = 1000 * metricValuesDict['BF-F-ND'] / sloc
    metricValuesDict['BF-F-NP-D'] = 1000 * metricValuesDict['BF-F-NP'] / sloc
    metricValuesDict['BF-F-PCL-D'] = 1000 * metricValuesDict['BF-F-PCL'] / sloc
    metricValuesDict['BF-F-RT-D'] = 1000 * metricValuesDict['BF-F-RT'] / sloc
    metricValuesDict['BF-F-UC-D'] = 1000 * metricValuesDict['BF-F-UC'] / sloc
    metricValuesDict['BF-F-MC-D'] = 1000 * metricValuesDict['BF-F-MC'] / sloc
    metricValuesDict['BF-F-UVP-D'] = 1000 * metricValuesDict['BF-F-UVP'] / sloc

def extract_and_calculate_metric_values(jsonResp):
    metricValues =  dict()
    if (len(jsonResp) > 0):
        metricTableEntry = jsonResp[0]
    else:
        print("ERROR: jsonResp contains 0 elements")
        print(jsonResp)
        return None
    metricsList = metricTableEntry['metrics']
    for metric in metricsList:
        if (metric['name'] == "Nesting Depth Assessment"):
            nestingDepthValueDict = metric['value']
            nestingDepthValuesList = nestingDepthValueDict['mapping']
            metricValues['BF-F-HND'] = nestingDepthValuesList[0]
            metricValues['BF-F-MND'] = nestingDepthValuesList[2]
            metricValues['BF-F-LND'] = nestingDepthValuesList[3]
            if (nestingDepthValuesList[1] != 0 or nestingDepthValuesList[4] != 0 or nestingDepthValuesList[5] != 0):
                print("WARNING: Nesting Depth Assessment value 1, 4 or 5 was not 0")
        elif (metric['name'] == "Cyclomatic Complexity Assessment"):
            ccValueDict = metric['value']
            ccValuesList = ccValueDict['mapping']
            metricValues['BF-HCC'] = ccValuesList[0]
            metricValues['BF-MCC'] = ccValuesList[2]
            metricValues['BF-LCC'] = ccValuesList[3]
            if (ccValuesList[1] != 0 or ccValuesList[4] != 0 or ccValuesList[5] != 0):
                print("WARNING: Cyclomatic Complexity Assessment value 1, 4 or 5 was not 0")
        else:
            if (metric['name'] in metricNamesIDsMapping):
                metricValues[metricNamesIDsMapping[metric['name']]] = float(metric['stringValue'])
    if(check_metricValues_contains_all_metrics(metricValues)):
        return metricValues
    print("ERROR: Not all metric values could be extracted, return empty list")
    return None
    
def sum_up_metric_values_for_files(metricValuesVersionFiles):
    metricValuesVersion = copy.deepcopy(metricValuesVersionFiles[1])
    #print("TRACE: Values for File 1 ....")
    metricValuesVersion['BF-F-CLC'] = metricValuesVersion['BF-F-CLC'] * metricValuesVersion['BF-SLOC']
    #print(metricValuesVersion)
    for fileCntr in range(2, len(metricValuesVersionFiles)+1):
        #print("TRACE: Values for File ", fileCntr, " ....")
        for entry in metricValuesVersion:
            if (entry == "BF-MAXCC"):
                #print("TRACE: Comparing values for maxcc: ", str(metricValuesVersion[entry]), " and ", metricValuesVersionFiles[fileCntr][entry])
                metricValuesVersion[entry] = max(metricValuesVersion[entry], metricValuesVersionFiles[fileCntr][entry])
            elif (entry == "BF-F-CLC"):
                metricValuesVersion[entry] = metricValuesVersion[entry] + (metricValuesVersionFiles[fileCntr][entry] * metricValuesVersionFiles[fileCntr]['BF-SLOC'])
                #print("TRACE: calculate CLC: ", metricValuesVersion[entry], " + ", metricValuesVersionFiles[fileCntr][entry], " * ", metricValuesVersionFiles[fileCntr]['BF-SLOC'])
            else:
                metricValuesVersion[entry] += metricValuesVersionFiles[fileCntr][entry]
    metricValuesVersion['BF-F-CLC'] = metricValuesVersion['BF-F-CLC'] / metricValuesVersion['BF-SLOC']
    #print(metricValuesVersion)
    return metricValuesVersion

def get_ordered_metric_values(metricValuesDict):
    valuesList = []
    for element in outputFileHeader:
        if (element == "id"):
            continue
        valuesList.append(metricValuesDict[element])
    return valuesList

def write_metric_values_to_output_file(f, valuesDict):
    csvWriter = csv.writer(f, delimiter=CSV_SEPERATOR_CHAR, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
    print("DEBUG: Writing header...")
    csvWriter.writerow(valuesDict[0])
    for lineNumber in range(1,VERSIONS+1):
        print("DEBUG: Writing line for Version ", lineNumber)
        row = [PROJECT_ID + "_" + str(lineNumber)]
        row.extend(valuesDict[lineNumber])
        csvWriter.writerow(row)

def write_output_files(metricValuesVersions):
    global CSV_SEPERATOR_CHAR
    global OUTPUT_FILE_NAME
    filePath = OUTPUT_DIR + "\\" + PROJECT_ID + "\\" + OUTPUT_FILE_NAME
    outputFile = open(filePath, "w", newline='')
    print("DEBUG: Writing values to output file: ", filePath)
    write_metric_values_to_output_file(outputFile, metricValuesVersions)
    outputFile.close()
    CSV_SEPERATOR_CHAR = ';'
    OUTPUT_FILE_NAME = "buggyFiles_staticMetrics_excel_format.csv"
    filePath = OUTPUT_DIR + "\\" + PROJECT_ID + "\\" + OUTPUT_FILE_NAME
    outputFileExcel = open(filePath, "w", newline='')
    print("DEBUG: Writing values to output file: ", filePath)
    write_metric_values_to_output_file(outputFileExcel, metricValuesVersions)
    outputFileExcel.close()

if __name__ == '__main__':
    print("Program Started, build REST Client...")
    client = TeamscaleClient(TEAMSCALE_URL, USERNAME, ACCESS_TOKEN, PROJECT_ID)
    firstVersionTimestamp = 1519862400000
    versionsInterval = 86400000
    metricValuesVersions = dict()
    metricValuesVersions[0] = outputFileHeader
    for versionCntr in range(0,VERSIONS):      # range end is excluding
        versionTimestamp = firstVersionTimestamp + versionCntr * versionsInterval + 10000000
        print("DEBUG: Processing version ", str(versionCntr+1), " unix timestamp: ",versionTimestamp)
        if (versionCntr+1 > VERSION_NEW_PREFIX):
            MC_PATH_PREFIX = MC_PATH_NEW_PREFIX
        buggyFiles = get_buggy_files(versionCntr+1)
        fileCntr = 1
        metricValuesVersionFiles = dict()
        for file in buggyFiles:
            jsonResp = get_request(client, versionTimestamp, file)
            metricValuesVersionFiles[fileCntr] = extract_and_calculate_metric_values(jsonResp)
            fileCntr += 1
        metricValuesVersion = sum_up_metric_values_for_files(metricValuesVersionFiles)
        if (check_metricValues_contains_all_metrics(metricValuesVersion)):
            calculate_proportion_and_density_values(metricValuesVersion)
            metricValuesVersions[versionCntr+1] = get_ordered_metric_values(metricValuesVersion)
        else:
            print("ERROR: Program won't export metric values for version " , versionCntr + 1)
            metricValuesVersions[versionCntr+1] = ["ERROR: not all metric values could be queried"]
    print("DEBUG: Finished extracting metric values")
    write_output_files(metricValuesVersions)
    print("Program finished!")
#
#
#
#
#
#