import shutil

SOURCE_FOLDER = "source"
PROJECT = "Chart"
MAX_VERSION = 26
SRC_BASE_DIR = "C:\\study\\SWDiag\\sharedFolder_UbuntuVM\\" + PROJECT + "_buggy"
TARGET_BASE_DIR = "C:\\study\\SWDiag\\sharedFolder_UbuntuVM\\" + PROJECT + "_unix_timestamps"
        
if __name__ == '__main__':
    print("Program started")
    firstVersionTimestamp = 1519862400000
    versionsInterval = 86400000
    srcDir = SRC_BASE_DIR + "\\1\\" + SOURCE_FOLDER
    targetDir = TARGET_BASE_DIR + "\\" + str(firstVersionTimestamp) + "\\" + SOURCE_FOLDER + "\\"
    print("DEBUG: copying " + srcDir + " to " + targetDir)
    shutil.copytree(srcDir, targetDir)
    for versionCntr in range(1,MAX_VERSION):
        srcDir = SRC_BASE_DIR + "\\" + str(versionCntr+1) + "\\" + SOURCE_FOLDER
        versionTimestamp = firstVersionTimestamp + versionCntr * versionsInterval
        targetDir = TARGET_BASE_DIR + "\\" + str(versionTimestamp) + "\\" + SOURCE_FOLDER + "\\"
        print("DEBUG: copying " + srcDir + " to " + targetDir)
        shutil.copytree(srcDir, targetDir)
    print("Program finished!")