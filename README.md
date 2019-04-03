# DS_Agent_Report

AUTHOR		: Yanni Kashoqa

TITLE		: Deep Security Agent Information

VERSION		: 0.1

DESCRIPTION	: This Powershell script will perform report the Deep Security Agent status information from Deep Security on Premise

FEATURES
The ability to perform the following:-
- Access the Deep Security Manager using SOAP protocol to pull Agent status information

REQUIRMENTS
- Powershell 5.1
- Create a DS-Config.json in the same folder with the following content modified to fit your environment:

{
    "MANAGER": "dsm.domain.local",
    "PORT": "4119",
    "TENANT": "",
    "USER_NAME": "",
    "PASSWORD": "",
    "REPORTFILE" : "DSaaS_Agent_Report.csv"
}

