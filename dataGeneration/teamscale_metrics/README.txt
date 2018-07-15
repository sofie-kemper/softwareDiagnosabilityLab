1. Setup Teamscale
    1a Download and install teamscale https://www.cqse.eu/de/produkte/teamscale/testen/
    1b copy license file into config folder

2. Prepare Projects for teamscale analysis
    2a Checkout all versions of a project (defects4j checkout), e.g. via checkoutProjects bash script
    2b Change folder structure: The foldername of each version must be a unix timestamp

3. Analyze the project via teamscale
    3a start teamscale server via cmd line
    3b open http://localhost:8080/ in browser
    3c create new project, add repository as "multi-versioned-file-system"
    3d define the analysis profile (add/remove smells that should (not) be detected)
    3e run analysis in teamscale of all versions of one project
    
4. Export results
    4a get https://github.com/cqse/teamscale-client-python to access the REST-API of teamscale which is documented here http://localhost:8080/servicedoc.html
    4b run one of the scripts td_buggyFiles_getMetrics.py or td_getmetric-table.py to query and export the results
    

Script td_getmetric-table.py
    queries the metric values from teamscale and writes them into a .csv file for one project
    global variables at the top of the document have to be adjusted for each project

Script td_buggyFiles_getMetrics.py
    queries the modified classes for each version from the defects4j repository
    exports metrics only for the changed files for each version of a project