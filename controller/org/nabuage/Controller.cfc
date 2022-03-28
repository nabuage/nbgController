component output="false" displayname="" {

    public function init(){
        VARIABLES.urlData = StructNew();
        VARIABLES.formData = StructNew();
        VARIABLES.requestData = StructNew();
        VARIABLES.urlData.action = "";
        VARIABLES.requestAction = "";
        VARIABLES.responseType = "html";
        VARIABLES.responseData = StructNew();
        return this;
    }

    public void function run(string controllerLocation = "controller") {
        var fileName = GetFileFromPath(CGI.PATH_TRANSLATED);
        var controllerCfc = "";
        var separator = "";
        var controllerDirectoryName = "";
        var controllerFile = "";
        var controllerDirectory = "";        
        var controllerFileName = "";
        var controllerList = "";
        var fileIndex = 0;

        if (structKeyExists(APPLICATION, "nbgController") AND structKeyExists(APPLICATION.nbgController, fileName)) {
            createObject("component", APPLICATION.nbgController[fileName]).init().process();
        }
        else {
            separator = Left(CGI.PATH_TRANSLATED, 1);
            controllerDirectoryName = ARGUMENTS.controllerLocation;
            controllerFile = replace(CGI.PATH_TRANSLATED, CGI.SCRIPT_NAME, "") & separator & controllerDirectoryName & replace(CGI.SCRIPT_NAME, ".cfm", ".cfc");
            controllerDirectory = GetDirectoryFromPath(controllerFile);

            if (directoryExists(controllerDirectory)) {
                controllerFileName = replace(fileName, ".cfm", ".cfc");
                controllerList = directoryList(controllerDirectory, false, "name", "*.cfc");
    
                for (fileIndex = 1; fileIndex LTE arrayLen(controllerList); fileIndex = fileIndex + 1) {
    
                    if (findNoCase(controllerFileName, controllerList[fileIndex])) {
                        controllerCfc = replaceNoCase(CGI.SCRIPT_NAME, controllerFileName, controllerList[fileIndex]);
                        controllerCfc = controllerDirectoryName & replace(controllerCfc, "/", ".", "all");
                        controllerCfc = replace(controllerCfc, ".cfm", "");

                        if (!structKeyExists(APPLICATION, "nbgController")) {
                            APPLICATION["nbgController"] = structNew();
                        }
                        else {
                            if (!structKeyExists(APPLICATION.nbgController, fileName)) {
                                APPLICATION.nbgController[fileName] = controllerCfc;
                            }
                        }
                        createObject("component", controllerCfc).init().process();
                        break;
                    }                    
                }
            }
        }
    }

    /*
        This function gets called before specific action - [onData, onEdit, onCreate, onUpdate, onDelete] is performed.
    */
    private void function preAction(required string action) {
        FORM.action = ARGUMENTS.action;
        VARIABLES.requestAction = ARGUMENTS.action;
        setParam();
    }

    /*
        This function gets called after specific action [onData, onEdit, onCreate, onUpdate, onDelete] is performed.
    */
    private void function postAction(required string action) {
        
        //By default, if responseType type is set to "json", responsd with json format by outputting the [responseData] variable.
        if (VARIABLES.responseType EQ "json") {
            if (ARGUMENTS.action EQ "data") {                
                outputContent(VARIABLES.responseData, "query", "text/json");
            }
            else {
                outputContent(VARIABLES.responseData, "struct", "text/json");
            }            
        }
        else if (VARIABLES.responseType EQ "text") {
            outputContent(VARIABLES.responseData, "string", "text/html");
        }
        else if (VARIABLES.responseType EQ "plain") {
            outputContent(VARIABLES.responseData, "string", "text/plain");
        }

        setRequestData();
        StructAppend(REQUEST, VARIABLES.requestData, false);
    }

    private void function outputContent(required any data, required string dataType, required string responseType) {
        var response = "";

        if (ARGUMENTS.dataType eq "string") {
            response = ARGUMENTS.data;
        }
        else {
            response = serializeJSON(ARGUMENTS.data, ARGUMENTS.dataType);
        }
        
        response = ToBinary(ToBase64(response) );

        cfheader(name="Content-length", value=ArrayLen(response));

        cfcontent(type=ARGUMENTS.responseType, variable=response);
    }

    /*
        This calls the appropriate default action [onData, onEdit, onCreate, onUpdate, onDelete].
        This is purely based on GET REQUEST type and value of query parameters - [action] and/or [id]
        AND POST REQUEST type and value of FORM variables - [action] and/or [id].
        GET REQUEST and URL.action = ACTION, call onData(). URL.id can be defined.
        GET REQUEST and URL.id = NUMBER, call onEdit(). URL.action must not be defined. This can be used to view entity data as well.
        GET REQUEST and URL.action and URL.id are not defined, call onNew().
        GET POST and FORM.action = "new" and FORM.id = NUMBER, call onCreate().
        GET POST and FORM.action = "edit" and FORM.id = NUMBER, call onUpdate().
        GET POST and FORM.action = "delete" and FORM.id = NUMBER, call onDelete().
    */
    public void function process() {

        switch (CGI.REQUEST_METHOD) {
            case "GET": {

                if (StructKeyExists(URL, "action")) { // *?action=
                    preAction("data");
                    onData();
                    postAction("data");
                }
                else {
                    if (StructKeyExists(URL, "id") AND URL.id NEQ "") { // *?id=NUMBER         
                        preAction("edit");
                        onEdit();
                        postAction("edit");
                    }
                    else { // *
                        preAction("new");
                        onNew();
                        postAction("new");
                    }                    
                }

                break;                 
            }
            case "POST": {
                if (StructKeyExists(FORM, "id") AND StructKeyExists(FORM, "action")) {
                    switch(FORM.action){
                        case "new": {
                            preAction("create");
                            onCreate();
                            postAction("create");
                            break;
                        }
                        case "edit": {
                            preAction("update");
                            onUpdate();
                            postAction("update");
                            break;
                        }
                        case "delete": {
                            preAction("delete");
                            onDelete();
                            postAction("delete");
                            break;
                        }
                        default: {
                            preAction(FORM.action);
                            onPost();
                            postAction(FORM.action);
                        }
                    }
                }

                break;
            }
        }
    }

    private void function addRequestData(required string name, required any data) {
        VARIABLES.requestData[ARGUMENTS.name] = ARGUMENTS.data;
    }

    private void function setResponseType(required string type) {
        VARIABLES.responseType = ARGUMENTS.type;
    }

    private void function setResponseData(required struct data) {
        VARIABLES.responseData = ARGUMENTS.data;
    }

    /*
        Override function on "data" POST request.
    */
    public boolean function onData() {
        
    }

    /*
        Override function on "create" POST request.
    */
    private void function onCreate() {

    }

    /*
        Override function on "update" POST request.
    */
    private void function onUpdate() {

    }

    /*
        Override function on "delete" POST request.
    */
    private void function onDelete() {

    }

    /*
        Override function on "post" POST request.
        If FORM.action is not new, edit, or delete.
    */
    private void function onPost() {

    }

    /*
        Override function on "edit" GET request.
        Setup page for edit - load data into form for editing. 
    */
    private void function onEdit() {

    }

    /*
        Setup page for new object/entity - empty form.
    */
    private void function onNew() {

    }

    /*
        Set request data.
        Data that will be displayed in the page.
        Example: Dropdown items.
    */
    private void function setRequestData() {
        
    }

    /*
        Set default URL and FORM variables.
    */
    public void function setParam() {

    }

    /*
        name: Name of the variable to create - URL.* or FORM.*.
        type: Type of the variable - string, numeric, etc.
        value: Value of the variable.
        sanitize: Security cleaning of the value.        
        validateValue: Should the value be validated based on lenght or range.
        validationName: Assign a name to the current validation. This is used to group succeeding validations.
        typeValidationMessage: Validation message to show if the [type] of the [value] is not valid.  For example: type = "numeric" but value = "".
        minLength: The required minimum number of characters of the [value].
        maxLength: The required maximum number of characters of the [value].
        lengthValidationMessage: Validation message to show if [minLength] or [maxLength] is not valid.
        minRange: The required minimum range of the [value].
        maxRange: The required maximum range of the [value].
        rangeValidationMessage: Validation message to show if [minRange] or [maxRange] is not valid.
        rangeValueFormat: Format pattern to use for [value] and [minRange/maxRange].  This is used for date format.
    */
    private void function param(required string name, 
                                required string type, 
                                required any value, 
                                boolean sanitize = true,
                                boolean validateValue = false, 
                                string validationName = "", 
                                string typeValidationMessage = "", 
                                numeric minLength = 0,
                                numeric maxLength = 0, 
                                string lengthValidationMessage = "", 
                                any minRange = "", 
                                any maxRange = "", 
                                string rangeValidationMessage = "",
                                string rangeValueFormat = "",
                                string regExPattern = "",
                                string regExPatternMessage = "") {
        var paramName = ListToArray(ARGUMENTS.name, ".");
        var allowEmpty = true;
        var paramValue = "";// Initial value

        
        //setup param types for which not to allow empty values
        if (ARGUMENTS.type EQ "numeric" OR ARGUMENTS.type EQ "boolean")  {
            allowEmpty = false;
        } 
        
        if (isDefined("#ARGUMENTS.name#")) { //if variable is already defined get its value
            paramValue = evaluate(ARGUMENTS.name);
        }
        else if (ARGUMENTS.value NEQ "") {
            paramValue = ARGUMENTS.value; //if default value its defined get that value
        } 
        
        //do not validate empty values unless stated otherwise
        if (Len(paramValue) OR NOT allowEmpty) {
            if (isValid(ARGUMENTS.type, paramValue)) {
                addRequestMessage("error", "validation", ARGUMENTS.validationName, ARGUMENTS.typeValidationMessage, paramName);
            }
        }
        
        if (ARGUMENTS.sanitize AND Len(paramValue)) {
            if (ARGUMENTS.type EQ "string") {
                //TODO: paramValue = sanitize(paramValue);
            }
            else if (ARGUMENTS.type EQ "any") {
                //TODO: paramValue = sanitize(paramValue);
            }
        }
        
        //If param that was passed is valid value
        //Create variable on our caller page from ATTRIBUTES.name and set value
        switch(UCase(paramName[1])) {
            case "URL":
                URL[paramName[2]] = paramValue;
                VARIABLES.urlData[paramName[2]] = paramValue;
                break;
            case "FORM":
                FORM[paramName[2]] = paramValue;
                VARIABLES.formData[paramName[2]] = paramValue;
                break;
        }

        if (ARGUMENTS.validateValue) {
            validate(ARGUMENTS.name, 
                        ARGUMENTS.type, 
                        paramValue, 
                        ARGUMENTS.validationName, 
                        ARGUMENTS.typeValidationMessage,                         
                        ARGUMENTS.minLength, 
                        ARGUMENTS.maxLength, 
                        ARGUMENTS.lengthValidationMessage, 
                        ARGUMENTS.minRange, 
                        ARGUMENTS.maxRange, 
                        ARGUMENTS.rangeValidationMessage,
                        ARGUMENTS.rangeValueFormat,
                        ARGUMENTS.regExPattern,
                        ARGUMENTS.regExPatternMessage);            
        }
    }

    private void function validate(required string name, 
                                    required string type, 
                                    required any value,
                                    string validationName = "", 
                                    string typeValidationMessage = "",                                     
                                    numeric minLength = 0,
                                    numeric maxLength = 0, 
                                    string lengthValidationMessage = "", 
                                    any minRange = "", 
                                    any maxRange = "", 
                                    string rangeValidationMessage = "",
                                    string rangeValueFormat = "",
                                    string regExPattern = "",
                                    string regExPatternMessage = "") {

        var paramNames = ListToArray(ARGUMENTS.name, ".");
        var validationType = "error";
        var paramName = "";

        if (ArrayLen(paramNames) GT 1) {
            validationType = paramNames[1];
            paramName = paramNames[2];
        }
        else {
            paramName = paramNames[1];
        }

        if (ARGUMENTS.type EQ "numeric" AND NOT IsNumeric(ARGUMENTS.value)) {
            addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.typeValidationMessage, paramName);
        }

        if (ARGUMENTS.minLength GT 0 AND Len(ARGUMENTS.value) LT ARGUMENTS.minLength) {
            addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.lengthValidationMessage, paramName);
        }
        else if (ARGUMENTS.maxLength GT 0 AND Len(ARGUMENTS.value) GT ARGUMENTS.maxLength) {
            addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.lengthValidationMessage, paramName);
        }

        if (ARGUMENTS.minRange NEQ "") {
            if (IsNumeric(ARGUMENTS.minRange) AND IsNumeric(ARGUMENTS.value) AND ARGUMENTS.value LT ARGUMENTS.minRange) {
                addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.rangeValidationMessage, paramName);
            }
            else if (IsDate(ARGUMENTS.minRange) AND IsDate(ARGUMENTS.value) AND ARGUMENTS.rangeValueFormat NEQ "" AND ParseDateTime(ARGUMENTS.value, ARGUMENTS.rangeValueFormat) LT ParseDateTime(ARGUMENTS.minRange, ARGUMENTS.rangeValueFormat)) {
                addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.rangeValidationMessage, paramName);
            }
            
        }

        if (ARGUMENTS.maxRange NEQ "") {
            if (IsNumeric(ARGUMENTS.maxRange) AND IsNumeric(ARGUMENTS.value) AND ARGUMENTS.rangeValueFormat NEQ "" AND ARGUMENTS.value GT ARGUMENTS.maxRange) {
                addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.rangeValidationMessage, paramName);
            }
            else if (IsDate(ARGUMENTS.maxRange) AND IsDate(ARGUMENTS.value) AND ARGUMENTS.rangeValueFormat NEQ "" AND ParseDateTime(ARGUMENTS.value, ARGUMENTS.rangeValueFormat) GT ParseDateTime(ARGUMENTS.maxRange, ARGUMENTS.rangeValueFormat)) {
                addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.rangeValidationMessage, paramName);
            }
        }

        if (ARGUMENTS.regExPattern NEQ "") {
            if (NOT IsValid("regex", ARGUMENTS.value, ARGUMENTS.regExPattern)) {
                addRequestMessage(validationType, "validation", ARGUMENTS.validationName, ARGUMENTS.regExPatternMessage, paramName);
            }
        }
    }

    private void function addRequestMessage() {
        var type = "NOTYPE";
        var groupType = "NOGROUP";
        
        if (NOT StructKeyExists(REQUEST, "nbgRequestMessage")){
            REQUEST.nbgRequestMessage = StructNew();
        }
        
        if (ARGUMENTS.messageType NEQ ""){
            type = ARGUMENTS.messageType;
        }
        
        if (ARGUMENTS.messageGroupType NEQ ""){
            groupType = type & ARGUMENTS.messageGroupType;
        }
        else{
            groupType = type & groupType;
        }
        
        if (NOT StructKeyExists(REQUEST.nbgRequestMessage, groupType)){
            REQUEST.nbgRequestMessage[groupType] = StructNew();
        }
        
        REQUEST.nbgRequestMessage[groupType].type = type;
        REQUEST.nbgRequestMessage[groupType].header = ARGUMENTS.messageGroupTypeText;
        
        if (NOT StructKeyExists(REQUEST.nbgRequestMessage[groupType], "messages")){
            REQUEST.nbgRequestMessage[groupType].messages = ArrayNew(1);
        }
        
        ArrayAppend(REQUEST.nbgRequestMessage[groupType].messages, ARGUMENTS.message);
        
        if (NOT StructKeyExists(REQUEST.nbgRequestMessage[groupType], "invalidFields")){
            REQUEST.nbgRequestMessage[groupType].invalidFields = ArrayNew(1);
        }
            
        if (IsDefined("ARGUMENTS.invalidField")) {
            ArrayAppend(REQUEST.nbgRequestMessage[groupType].invalidFields, ARGUMENTS.invalidField);
        }
    }

    private boolean function isFormValid() {
        var isValid = true;
        var counter = 0;
        var messageItem = "";
        var item = "";

        if (StructKeyExists(REQUEST, "nbgRequestMessage")) {
            for (messageItem in REQUEST.nbgRequestMessage) {
                if (UCase(REQUEST.nbgRequestMessage[messageItem].type) EQ "FORM") {
                    isValid = false;
                    break;
                }
            }

            if (NOT isValid) {
                if (StructKeyExists(VARIABLES.responseData, "errors")) {
                    StructAppend(VARIABLES.responseData.errors, REQUEST.nbgRequestMessage, false);
                }
                else {
                    VARIABLES.responseData.errors = REQUEST.nbgRequestMessage;
                }
            }            
        }
        return isValid;
    }
}
