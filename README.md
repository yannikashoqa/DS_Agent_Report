# DS_Agent_Report

AUTHOR		: Yanni Kashoqa

TITLE		: Deep Security Agent Information

DESCRIPTION	: This Powershell script will report the Deep Security Agent status information from Deep Security on Premise and Deep Security as a Service

FEATURES
The ability to perform the following:-
- Access the Deep Security Manager using SOAP protocol to pull Agent status information

REQUIRMENTS
- Powershell 5.1
- Create a DS-Config.json in the same folder with the following content modified to fit your environment:

{
    "MANAGER": "",
    "PORT": "",
    "TENANT": "",
    "USER_NAME": "",
    "PASSWORD": "",
    "REPORTNAME" : "DSaaS_Agent_Report"
}

- For DSaaS, MANAGER should be "app.deepsecurity.trendmicro.com" and the PORT is "443".
- For Deep Security On-Premise, the MANAGER should be the FQDN of the DSM server and the PORT is "4119".
- The TENANT is used when connecting to DSaaS and should reflect your Tenant name.
