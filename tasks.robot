*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             DateTime
Library             OperatingSystem
Library             Collections
Library             RPA.Archive
Library             RPA.RobotLogListener
# Library    RPA.DocumentAI


*** Variables ***
${Orders}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${Orders}    Get Orders
    Open Order Form
    Loop Orders    ${Orders}
    Create a ZIP file of receipt PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${Orders}    Read table from CSV    input/orders.csv
    RETURN    ${Orders}

Open Order Form
    Click Element    xpath:/html/body/div/header/div/ul/li[2]/a

Fill the form
    [Arguments]    ${order}
    Log    ${order}

    # Save the order details in Variables
    ${order_number}    Set Variable    ${order}[Order number]
    ${head}    Set Variable    ${order}[Head]
    ${body}    Set Variable    ${order}[Body]
    ${legs}    Set Variable    ${order}[Legs]
    ${address}    Set Variable    ${order}[Address]

    # Get other Variables
    ${timestamp}    Get Current Date    result_format=%Y-%m-%d

    # Fill in the Form with Head, Body, Kegs and Address
    Select From List By Value    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[1]/select    ${head}
    Select Radio Button    body    ${body}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${legs}
    Input Text    xpath://*[@id="address"]    ${address}
    Click Button    xpath://*[@id="preview"]
    Click Button    xpath://*[@id="order"]
    Element Should Be Visible    xpath://*[@id="receipt"]/h3
    ${pdf}    Store the receipt as a PDF file    ${order_number}    ${timestamp}
    ${img}    Take a screenshot of the robot    ${order_number}    ${timestamp}
    Embed the robot screenshot to the receipt PDF file    ${img}    ${pdf}
    Click Button    xpath://*[@id="order-another"]

Loop Orders
    [Arguments]    ${Orders}
    Mute Run On Failure    Fill the form
    FOR    ${order}    IN    @{Orders}
        Log    ${order}
        Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
        Wait Until Keyword Succeeds    10x    1s    Fill the form    ${order}
    END

Store the receipt as a PDF file
    [Arguments]    ${order_number}    ${timestamp}
    ${output_path}    Catenate    SEPARATOR=
    ...    ${OUTPUT_DIR}
    ...    ${/}
    ...    receipts
    ...    ${/}
    ...    ${timestamp}
    ...    _receipt_
    ...    ${order_number}
    ...    .pdf
    Wait Until Element Is Visible    xpath://*[@id="receipt"]/h3
    ${receipt_html}    Get Element Attribute    xpath://*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${output_path}
    RETURN    ${output_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}    ${timestamp}
    ${output_path}    Catenate    SEPARATOR=
    ...    ${OUTPUT_DIR}
    ...    ${/}
    ...    robots
    ...    ${/}
    ...    ${timestamp}
    ...    _robot_
    ...    ${order_number}
    ...    .jpg
    Wait Until Element Is Visible    xpath://*[@id="robot-preview-image"]
    ${robot_img}    Screenshot    xpath://*[@id="robot-preview-image"]    ${output_path}
    RETURN    ${output_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${img}    ${pdf}
    ${files}    Create List    ${pdf}    ${img}
    Add Files To Pdf    ${files}    ${pdf}
    Remove File    ${img}

Create a ZIP file of receipt PDF files
    ${path_receipts}    Catenate    SEPARATOR=    ${OUTPUT_DIR}    ${/}    receipts
    ${path_zip}    Catenate    SEPARATOR=    ${OUTPUT_DIR}    ${/}    receipts.zip
    Archive Folder With Zip    ${path_receipts}    ${path_zip}
    Remove Directory    ${path_receipts}    TRUE
    ${path_robots}    Catenate    SEPARATOR=    ${OUTPUT_DIR}    ${/}    robots
    Remove Directory    ${path_robots}    TRUE
