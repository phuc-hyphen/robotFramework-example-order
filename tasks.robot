*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download file orders
    Open the robot order website
    @{orders}=    Get orders
    FOR    ${element}    IN    @{orders}
        Close the annoying modal
        Run Keyword And Continue On Failure    Fill the form    ${element}
        ${pdf}=    Store the receipt as a PDF file    ${element}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${element}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create ZIP package from PDF files
    # Cleanup temporary PDF directory


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Close the annoying modal
    Click Button When Visible    //button[normalize-space()='OK']

Download file orders
    Download    https://robotsparebinindustries.com/orders.csv

Get orders
    ${orders}=    Read table from CSV    orders.csv    delimiters=","
    RETURN    ${orders}

Fill the form
    [Arguments]    ${order}
    Select From List By Index    //select[@id='head']    ${order}[Head]
    Click Button When Visible    //input[@value='${order}[Body]']
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    //input[@id='address']    ${order}[Address]
    Click Button    //button[@id='preview']

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Scroll Element Into View    //button[@id='order']
    Double Click Element    //button[@id='order']
    ${ex}=    Is Element Visible    //button[@id='order']
    IF    ${ex}==True    Click Button    //button[@id='order']

    Wait Until Element Is Visible    //div[@id='receipt']    timeout=10000
    ${order_results_html}=    Get Element Attribute    //div[@id='receipt']    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}receipt_${order_number}.pdf
    RETURN    receipt_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    //div[@id='robot-preview-image']
    Screenshot    //div[@id='robot-preview-image']    ${OUTPUT_DIR}${/}screenshot_${order_number}.png
    RETURN    screenshot_${order_number}.png

Go to order another robot
    Scroll Element Into View    //button[@id='order-another']
    Click Button    //button[@id='order-another']

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${OUTPUT_DIR}${/}${pdf}
    Add Watermark Image To Pdf    ${OUTPUT_DIR}${/}${screenshot}    ${OUTPUT_DIR}${/}${pdf}
    Close Pdf    ${OUTPUT_DIR}${/}${pdf}

Create ZIP package from PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}    orders.zip

Cleanup temporary PDF directory
    Remove Directory    ${OUTPUT_DIR}    True
