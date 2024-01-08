#!/bin/bash
export LC_ALL=C.UTF-8
SERVER_URL=%TC_SERVER_URL%
AUTH_PASSWORD=%TC_DASHBOARD_USER_TOKEN%
OUTPUT_HTML="output.html"
BUILD_STEPS_NAMES=("Maturity Assesment Score (Score is Out Of 4)" "Compilation" "Unit Test" "Integration Test" "Sonar Qube" "Coverity Test" "Mutation Test" "Compilation - Angular" "Unit Test - Angular" "Mutation Test - Angular" "Last Build Chain Completion Time")
PROJECT_IDS="Zaidyn_Zce_ZceFi_PaInsightsstore Zaidyn_Zce_ZceFi_TenantManagerMaster Zaidyn_Zce_ZceFi_FiAdminPortal_CeFiAdminPortal Zaidyn_Zce_ZceMi_VersoFiMyinsights Zaidyn_Zce_OrchestrationEngine_OrchestrationEngine Zaidyn_Zce_OeFs_OeFieldSuggestions Zaidyn_Zce_OeNba_ObNba Zaidyn_Zce_OeRpa_OeRpa Zaidyn_Zce_OeFs_2_OeReporting Zaidyn_Zce_ZsSisenseDotnetSdk_ZsSisenseDotnetSdk Zaidyn_Zce_OeOcUi_OeOcUi Zaidyn_Zce_ConfigurationLib_OeAlgorithmLibrary Zaidyn_Zce_OeNba_OeNbaMl Zaidyn_Zfp_Fd_SpmAlignment Zaidyn_Zfp_Fd_SpmMasterData Zaidyn_Zfp_Fd_SpmBrm Zaidyn_Zfp_Fir_SpmReports Zaidyn_Zfp_Fir_SpmResource Zaidyn_Zfp_Fio_Zico Zaidyn_Zfp_Common_SpmNotification Zaidyn_Zfp_Common_SpmScheduler Zaidyn_Zfp_Common_SpmShared Zaidyn_Zfp_Common_VersoAppCore Zaidyn_Zfp_Fp_SpmDdl Zaidyn_Zfp_Fp_SpmSharedUi Zaidyn_Pf_Sc_Geocoding Zaidyn_Pf_Zac Zaidyn_Pf_Vdf_AppManagement Zaidyn_Pf_Vdf_ZsAwsRe433 Zaidyn_Pf_Df_ZdfPubSub Zaidyn_Pf_Idm_IDMNextService Zaidyn_Pf_Idm_IDMNextJavaSdk Zaidyn_Pf_Idm_IDMNextDotNetCoreSdk Zaidyn_Pf_Idm_IDMNextPythonSdkCicd Zaidyn_DA_Zdh"
echo "<html>
<head>
    <title>TeamCity Status Dashboard</title>
<style>
    table {
        border-collapse: collapse;
        width: 90%;
        margin: auto;
    }
    th, td {
        border: 1px solid black;
        vertical-align: middle;
    }
    th {
        font-weight: bold;
        background-color: gray;
    }
    caption {
        caption-side: top;
        font-size: 1.5em;
        background-color: darkgray;
        color: black;
        border: 1px solid black;
    }
    .success {
        color: green;
    }
    .failure {
        color: red;
    }
    .not-configured {
        color: green;
    }
    .not-triggered {
        color: red;
    }
    a {
    	color: blue;
    }
</style>
</head>
<body>
<table>
<caption><b>ZAIDYN CICD Consolidated Dashboard</b></caption>" > $OUTPUT_HTML
# Header row with BUILD_STEPS_NAMES
HEADER_ROW="<tr><th>Product Line</th><th>Application</th>"
# for BUILD_STEP_NAME in "${BUILD_STEPS_NAMES[@]}"; do
#     HEADER_ROW+="<th>$BUILD_STEP_NAME</th>"
# done
for BUILD_STEP_NAME in "${BUILD_STEPS_NAMES[@]}"; do
    if [ "$BUILD_STEP_NAME" == "Maturity Assesment Score (Score is Out Of 4)" ]; then
        HEADER_ROW+="<th>Maturity Assesment <br><span style=\"color: white;\">(Scoring against 4)</span></th>"
    else
        HEADER_ROW+="<th>$BUILD_STEP_NAME</th>"
    fi
done
HEADER_ROW+="</tr>"
echo $HEADER_ROW >> $OUTPUT_HTML

current_product=""
count=0
for PROJECT_ID in $PROJECT_IDS; do
    # Set the product name based on the count
    if [ $count -lt 13 ]; then
        PRODUCT_NAME="CE"
        colspan_value=13
    elif [ $count -lt 25 ]; then
        PRODUCT_NAME="FP"
        colspan_value=12
    elif [ $count -lt 34 ]; then
        PRODUCT_NAME="PF"
        colspan_value=9
    else
        PRODUCT_NAME="D&A"
        colspan_value=1
    fi
    if [ "$PRODUCT_NAME" != "$current_product" ]; then
        if [ "$current_product" != "" ]; then
            echo "</tr>" >> $OUTPUT_HTML
        fi
        echo "<tr><td rowspan=\"$colspan_value\" style=\"text-align: center;\"><b>$PRODUCT_NAME</b></td>" >> $OUTPUT_HTML
        current_product="$PRODUCT_NAME"
    else
        echo "<tr>" >> $OUTPUT_HTML
    fi
    PROJECT_URL="$SERVER_URL/project/$PROJECT_ID?projectTab=projectBuildChains"
    COMP_PROJECT_NAME=$(curl -s -H "Authorization: Bearer $AUTH_PASSWORD" "$SERVER_URL/app/rest/projects/id:$PROJECT_ID" | grep -oP '<project id="[^"]*" name="\K[^"]*')
    PROJECT_NAME="${COMP_PROJECT_NAME/ExistingBuilds/}"
    echo "<td><a href=\"$PROJECT_URL\" target=\"_blank\">${PROJECT_NAME,,}</a></td>" >> $OUTPUT_HTML
    for BUILD_STEP_NAME in "${BUILD_STEPS_NAMES[@]}"; do
        if [ "$BUILD_STEP_NAME" != "Last Build Chain Completion Time" ]; then
            if [ "$BUILD_STEP_NAME" == "Maturity Assesment Score (Score is Out Of 4)" ]; then
                echo "Script is running for Build Step $BUILD_STEP_NAME of Project $PROJECT_NAME"
                rowDataJson=$(curl -s -H "Authorization: Bearer $AUTH_PASSWORD" "$SERVER_URL/viewType.html?buildTypeId=$PROJECT_ID"_"MaturityAssessment&tab=maturityAssessment" | grep "const rowDataJson")
                assesmentScore=($(echo "$rowDataJson" | grep -oP '\[.*?\]' | sed 's/\[//; s/\]//; s/\], \[/\n/g' | cut -d',' -f2))
                sum=0
                no_element=0
                for element in "${assesmentScore[@]}"; do
                    sum=$(awk "BEGIN {print $sum + $element}")
                    no_element=$((no_element+1))
                done
                echo "Sum of the maturity assesment score is $sum for number of parameters $no_element"
                if [ "${#assesmentScore[@]}" -gt 0 ]; then
                    average=$(awk "BEGIN {print $sum / ${#assesmentScore[@]}}")
                    rounded_average=$(printf "%.0f" $average)
                    echo "Average maturity assesment score is $rounded_average"
                    echo "<td style=\"text-align: center;\"><a href=\"$SERVER_URL/buildConfiguration/$PROJECT_ID"_MaturityAssessment?buildTypeTab=maturityAssessment"\" target=\"_blank\">$rounded_average</a></td>" >> $OUTPUT_HTML
                else
                    echo "<td style=\"text-align: center;\"><a href=\"$SERVER_URL/buildConfiguration/$PROJECT_ID"_MaturityAssessment?buildTypeTab=maturityAssessment"\" target=\"_blank\">na</a></td>" >> $OUTPUT_HTML
                fi                
                average=$(awk "BEGIN {print $sum / ${#assesmentScore[@]}}")
                
            else
                echo "Script is running for Build Step $BUILD_STEP_NAME of Project $PROJECT_NAME"
                curl -s -H "Authorization: Bearer $AUTH_PASSWORD" "$SERVER_URL/app/rest/buildTypes?locator=project:(id:$PROJECT_ID)" | sed 's/>/>\n/g' > output.xml
                BUILD_STEP=$(grep "name=\"$BUILD_STEP_NAME\"" output.xml | grep -o 'id="[^"]*' | awk -F'"' '{print $2}' | awk -F'_' '{print $NF}')
                rm output.xml
                if [ -z "$BUILD_STEP" ]; then
                    STATUS="na"
                else
                    STATUS=$(curl -s -H "Authorization: Bearer $AUTH_PASSWORD" "$SERVER_URL/app/rest/buildTypes/$PROJECT_ID"_"$BUILD_STEP/builds?locator=running:any,branch:default:any,canceled:any,pinned:any,lookupLimit:1" | awk '{ print $11 }' | awk -F'"' '{print $2}')
                fi
                STATUS_CLASS=""
                if [ "$STATUS" == "na" ]; then
                    STATUS_CLASS="not-configured"
                elif [ "$STATUS" == "SUCCESS" ]; then
                    STATUS_CLASS="success"
                    LAST_RUN=$(curl -s -H "Authorization: Bearer $AUTH_PASSWORD" "$SERVER_URL/app/rest/buildTypes/$PROJECT_ID"_"$BUILD_STEP/builds?locator=running:any,branch:default:any,canceled:any,pinned:any,lookupLimit:1" | grep -oP '<finishOnAgentDate>\K[^<]+' | awk '{print substr($1,1,4) "-" substr($1,5,2) "-" substr($1,7,2) " " substr($1,10,2) ":" substr($1,12,2) ":" substr($1,14,2)}')
                elif [ "$STATUS" == "FAILURE" ]; then
                    STATUS_CLASS="failure"
                    STATUS="fail"
                    LAST_RUN=$(curl -s -H "Authorization: Bearer $AUTH_PASSWORD" "$SERVER_URL/app/rest/buildTypes/$PROJECT_ID"_"$BUILD_STEP/builds?locator=running:any,branch:default:any,canceled:any,pinned:any,lookupLimit:1" | grep -oP '<finishOnAgentDate>\K[^<]+' | awk '{print substr($1,1,4) "-" substr($1,5,2) "-" substr($1,7,2) " " substr($1,10,2) ":" substr($1,12,2) ":" substr($1,14,2)}')
                else
                    STATUS=$(curl -s -H "Authorization: Bearer $AUTH_PASSWORD" "$SERVER_URL/app/rest/buildTypes/$PROJECT_ID"_"$BUILD_STEP/builds?locator=running:any,branch:default:any,pinned:any,lookupLimit:1" | awk '{ print $11 }' | awk -F'"' '{print $2}')
                    if [ "$STATUS" == "SUCCESS" ]; then
                        STATUS_CLASS="success"
                    elif [ "$STATUS" == "FAILURE" ]; then
                        STATUS_CLASS="failure"
                        STATUS="fail"
                    fi
                fi
                echo "<td class=\"$STATUS_CLASS\">${STATUS,,}</td>" >> $OUTPUT_HTML
            fi
        fi
    done
    count=$((count+1))
	date_string=$(date -d "$LAST_RUN" "+%d/%b/%y %I:%M %p")
    last_word=$(echo "$date_string" | awk '{print $NF}')
    last_word_lower=$(echo "$last_word" | tr '[:upper:]' '[:lower:]')
    FORMATTED_DATE=$(echo "$date_string" | sed "s/$last_word/$last_word_lower/")
    formatted_timestamp=$(date -d "$LAST_RUN" +"%s")
    current_timestamp=$(date +"%s")
    time_difference=$((current_timestamp - formatted_timestamp))
    threshold=$((24 * 60 * 60))
    if [ $time_difference -gt $threshold ]; then
        echo "<td style='color:red;'>$FORMATTED_DATE</td>" >> $OUTPUT_HTML
    else
        echo "<td style='color:green;'>$FORMATTED_DATE</td>" >> $OUTPUT_HTML
    fi
    echo "</tr>" >> $OUTPUT_HTML
done
echo "</table>" >> $OUTPUT_HTML
echo "<hr/>" >> $OUTPUT_HTML
echo "</body>" >> $OUTPUT_HTML
echo "</html>" >> $OUTPUT_HTML