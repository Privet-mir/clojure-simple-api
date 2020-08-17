
*Settings
Library           HttpLibrary.HTTP
Library           String
Library           DateTime
* Variables
${SERVER}               localhost:4000
${JSON}                 {"title": "hello", "description": "world"}
* Test Cases
Post document
    [Documentation]
    Create Http Context    ${SERVER}     http
    Set Request Header      Content-Type    application/json
    Set Request Body        ${Json}
    HttpLibrary.HTTP.POST           /documents
    ${JsonForID}=   Get Response Body
    Log         ${JsonForID}

Get document
    Create Http Context    ${SERVER}     http
    HttpLibrary.HTTP.GET           /documents
    ${JsonForID}=   Get Response Body
    Log         ${JsonForID}

