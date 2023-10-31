#!/bin/bash
export LC_ALL=C.UTF-8
SERVER_URL="${TEAMCITY_SERVER_URL}"
TRIGGERED_BY="${TEAMCITY_BUILD_TRIGGEREDBY_USERNAME}"
AUTH_PASSWORD="${TEAMCITY_SYSTEM_TEAMCITY_AUTH_PASSWORD}"
OUTPUT_HTML="output.html"
PROJECT_IDS=$(curl -s -u $TRIGGERED_BY:$AUTH_PASSWORD "$SERVER_URL/httpAuth/app/rest/projects" | grep -o 'id="[^"]*' | awk -F'"' '{print $2}')
echo "<html>
<head>
    <title>TeamCity Build Status</title>
    <style>
        table {
            border-collapse: collapse;
            width: 50%;
        }
        th, td {
            border: 1px solid black;
            padding: 10px;
            text-align: left;
        }
        th {
            font-weight: bold;
        }
        .success {
            color: green;
        }
        .failure {
            color: red;
        }
    </style>
</head>
<body>" > $OUTPUT_HTML
for PROJECT_ID in $PROJECT_IDS; do
    if [[ "$PROJECT_ID" != "_Root" && "$PROJECT_ID" != "Dashboard" ]]; then
        PROJECT_URL="$SERVER_URL/project/$PROJECT_ID?projectTab=projectBuildChains"
        PROJECT_NAME=$(curl -s -u $TRIGGERED_BY:$AUTH_PASSWORD "$SERVER_URL/httpAuth/app/rest/projects/id:$PROJECT_ID" | grep -oP '<project id="[^"]*" name="\K[^"]*')
        echo "<h2>Project Name: $PROJECT_NAME <a href=\"$PROJECT_URL\" target=\"_blank\"><button>Go to Project</button></a></h2>" >> $OUTPUT_HTML
        echo "<table>
                <tr>
                </tr>" >> $OUTPUT_HTML        
        BUILD_STEPS=$(curl -s -u $TRIGGERED_BY:$AUTH_PASSWORD "$SERVER_URL/httpAuth/app/rest/buildTypes?locator=project:(id:$PROJECT_ID)" | grep -o 'id="[^"]*' | awk -F'"' '{print $2}' | awk -F '_' '{print $2}')        
        BUILD_STEP_ROW=""
        STATUS_ROW=""
        LAST_RUN_ROW=""
        for BUILD_STEP in $BUILD_STEPS; do
            STATUS=$(curl -s -u $TRIGGERED_BY:$AUTH_PASSWORD "$SERVER_URL/httpAuth/app/rest/buildTypes/$PROJECT_ID"_"$BUILD_STEP/builds?locator=running:any,branch:default:any,canceled:any,pinned:any,lookupLimit:1" | awk '{ print $11 }' | awk -F'"' '{print $2}')
            LAST_RUN=$(curl -s -u $TRIGGERED_BY:$AUTH_PASSWORD "$SERVER_URL/httpAuth/app/rest/buildTypes/$PROJECT_ID"_"$BUILD_STEP/builds?locator=running:any,branch:default:any,canceled:any,pinned:any,lookupLimit:1" | grep -oP '<finishOnAgentDate>\K[^<]+' | awk '{print substr($1,1,4) "-" substr($1,5,2) "-" substr($1,7,2) " " substr($1,10,2) ":" substr($1,12,2) ":" substr($1,14,2)}')
            STATUS_CLASS=""
            if [ "$STATUS" == "SUCCESS" ]; then
                STATUS_CLASS="success"
            elif [ "$STATUS" == "FAILURE" ]; then
                STATUS_CLASS="failure"
            fi
            BUILD_STEP_ROW+="<td>$BUILD_STEP</td>"
            STATUS_ROW+="<td class=\"$STATUS_CLASS\">$STATUS</td>"
            LAST_RUN_ROW+="<td>$LAST_RUN</td>"
        done
        echo "<tr>
                $BUILD_STEP_ROW
            </tr>
            <tr>
                $STATUS_ROW
            </tr>
            <tr>
                $LAST_RUN_ROW
            </tr>" >> $OUTPUT_HTML

        echo "</table>" >> $OUTPUT_HTML
        echo "<hr/>" >> $OUTPUT_HTML
    fi
done
echo "</body>
</html>" >> $OUTPUT_HTML
