/**
 * HelperSOQL - The provided code is an Apex class named HelperSOQL that is 
 * designed to parse and handle SOQL (Salesforce Object Query Language) queries.
 * The class contains several static sets that define SOQL keywords and functions, 
 * which are used to identify different parts of a SOQL query during parsing.
 * 
 * The main functionality of the class is encapsulated in the parseSOQL method, which 
 * takes a SOQL query string as input and returns a list of SOQLToken objects representing 
 * the parsed query. The method normalizes whitespace in the query and then iterates through 
 * each character to identify and tokenize different components such as string literals, 
 * keywords, functions, operators, and subqueries. It uses helper methods like isLetterOrDigit, 
 * isOperatorOrPunctuation, and isMultiCharOperator to classify characters and tokens appropriately.
 * 
 * The processNestedQueries method further processes the tokens to properly structure nested subqueries, 
 * ensuring that the hierarchy of the query is maintained. This method uses a custom Stack inner class to 
 * track the depth of nested subqueries and tags tokens with subquery depth information.
 * 
 * The reassembleSOQL method is a static method that takes a list of SOQLToken objects and reassembles 
 * them back into a SOQL query string. It handles spacing between tokens to ensure the query is correctly 
 * formatted.
 * 
 * The class also includes several inner classes: Stack, SOQLToken, and SOQLTokenList. The Stack class is 
 * a simple implementation of a stack data structure used to track subquery nesting. The SOQLToken class 
 * represents individual tokens in a SOQL query, with properties for the token's value and type. The 
 * SOQLTokenList class is a wrapper around a list of SOQLToken objects, providing methods to manipulate 
 * and query the list of tokens.
 * 
 * Overall, the HelperSOQL class provides a comprehensive set of tools for parsing, processing, and 
 * reassembling SOQL queries, making it easier to work with complex queries in Salesforce.
 * 
 * This class handles the complexities of SOQL syntax including:
 * - Field selections
 * - FROM clauses
 * - WHERE conditions
 * - Relationship queries
 * - Operators
 * - String literals
 * - Function calls
 * - Subqueries (in field lists and WHERE clauses)
 * - ORDER BY/GROUP BY/LIMIT/OFFSET clauses
 * - Nested subqueries (queries within queries)
 * 
 * Subquery handling includes:
 * - Subqueries in field lists: (SELECT Id FROM Contacts)
 * - Subqueries in WHERE clauses: WHERE Id IN (SELECT AccountId FROM Contact)
 * - Nested subqueries: (SELECT Id, (SELECT LineItemId FROM OrderItems) FROM Orders)
 */
public class HelperSOQL {

    private static final String SUBQUERY_START = 'SUBQUERY_START';
    private static final String SUBQUERY_END = 'SUBQUERY_END';
    private static final String KEYWORD = 'KEYWORD';
    private static final String NUMBR = 'NUMBR';
    private static final String IDENTIFIER = 'IDENTIFIER';
    private static final String OPERATOR = 'OPERATOR';
    private static final String VALUE = 'VALUE';
    private static final String DELIMITER = 'DELIMITER';
    private static final String FUNCTION = 'FUNCTION';
    private static final String OPEN_PAREN = 'OPEN_PAREN';
    private static final String CLOSE_PAREN = 'CLOSE_PAREN';
    private static final String STRING_LITERAL = 'STRING_LITERAL';
    private static final String SUBQUERY_MARKER = 'SUBQUERY_MARKER';
    private static final String MAIN_OBJECT = 'MAIN_OBJECT';
    private static final String ORDER_BY = 'ORDER_BY';
    private static final String UNKNOWN = 'UNKNOWN';

    // SOQL keywords
    private static Set<String> keywords = new Set<String>{
        'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'NOT',
        'BY', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET',
        'WITH', 'SECURITY_ENFORCED', 'USER_MODE',
        'FOR', 'VIEW', 'UPDATE', 'REFERENCE',
        'NULLS', 'FIRST', 'LAST', 'ASC', 'DESC', 'USING', 'SCOPE'
    };
    
    // SOQL functions
    private static Set<String> functions = new Set<String>{
        'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'CALENDAR_MONTH',
        'CALENDAR_QUARTER', 'CALENDAR_YEAR', 'DAY_IN_MONTH',
        'DAY_IN_WEEK', 'DAY_IN_YEAR', 'DAY_ONLY', 'FORMAT',
        'FISCAL_MONTH', 'FISCAL_QUARTER', 'FISCAL_YEAR', 'HOUR_IN_DAY',
        'WEEK_IN_MONTH', 'WEEK_IN_YEAR', 'CONVERTCURRENCY'
    };

    /**
     * Parses a SOQL query string into tokens
     * @param soqlQuery The SOQL query to parse
     * @return List of SOQLToken objects representing the parsed query
     
         HelperSOQL h = new HelperSOQL();
        String jsonStr = JSON.serializePretty(h.parseSOQL('select Account.ParentId, Account.Name, Account.NumberOfEmployees, Type, (Select Name, Contact.Phone, Contact.Email, CreatedBy.Name, CreatedBy.Profile.Name From Contacts Order By Name) from Account where Id IN (SELECT AccountId FROM Contact where Title = \'SVP, Operations\')'));
        System.debug(LoggingLevel.DEBUG, jsonStr);
     */
    public SOQLTokenList parseSOQL(String soqlQuery) {
        SOQLTokenList tokens = new SOQLTokenList();
        
        if (String.isBlank(soqlQuery)) {
            return tokens;
        }
        
        // Normalize whitespace
        soqlQuery = soqlQuery.trim().replaceAll('\\s+', ' ');
        
        Integer i = 0;
        Boolean inStringLiteral = false;
        String currentToken = '';
        String currentType = '';
        Integer parenDepth = 0;
        List<Integer> subqueryStartPositions = new List<Integer>();
        
        while (i < soqlQuery.length()) {
            String currentChar = soqlQuery.substring(i, i+1);
            
            // Handle string literals (text in single quotes)
            if (currentChar.equals('\'')) {
                if (inStringLiteral) {
                    currentToken += currentChar;
                    tokens.add(new SOQLToken(currentToken, STRING_LITERAL));
                    currentToken = '';
                    inStringLiteral = false;
                } else {
                    if (currentToken != '') {
                        tokens.add(new SOQLToken(currentToken, identifyTokenType(currentToken)));
                        currentToken = '';
                    }
                    currentToken += currentChar;
                    inStringLiteral = true;
                }
                i++;
                continue;
            }
            
            if (inStringLiteral) {
                currentToken += currentChar;
                i++;
                continue;
            }
            
            // Handle opening parenthesis - check for subquery
            if (currentChar.equals('(')) {
                if (currentToken != '') {
                    tokens.add(new SOQLToken(currentToken, identifyTokenType(currentToken)));
                    currentToken = '';
                }
                
                tokens.add(new SOQLToken(String.valueOf(currentChar), OPEN_PAREN));
                parenDepth++;
                
                // Look ahead for SELECT keyword to identify subquery regardless of context
                Integer lookAheadPos = i + 1;
                String lookAhead = '';
                // Skip whitespace
                while (lookAheadPos < soqlQuery.length() && soqlQuery.substring(lookAheadPos, lookAheadPos+1).equals(' ')) {
                    lookAheadPos++;
                }
                
                // Get potential keyword
                while (lookAheadPos < soqlQuery.length() && 
                       isLetterOrDigit(soqlQuery.substring(lookAheadPos, lookAheadPos+1))) {
                    lookAhead += soqlQuery.substring(lookAheadPos, lookAheadPos+1);
                    lookAheadPos++;
                }
                
                // If this is a SELECT, mark as start of subquery - these can appear in:
                // 1. Field list (e.g., SELECT Id, (SELECT Name FROM Contacts) FROM Account)
                // 2. WHERE clause (e.g., WHERE Id IN (SELECT AccountId FROM Contact))
                // 3. Other expressions (e.g., FOR UPDATE clause)
                if (lookAhead.equalsIgnoreCase('SELECT')) {
                    subqueryStartPositions.add(tokens.size() - 1); // Position of the open paren
                    tokens.add(new SOQLToken(SUBQUERY_START, SUBQUERY_MARKER));
                }
                
                i++;
                continue;
            }
            
            // Handle closing parenthesis - check for end of subquery
            if (currentChar.equals(')')) {
                if (currentToken != '') {
                    tokens.add(new SOQLToken(currentToken, identifyTokenType(currentToken)));
                    currentToken = '';
                }
                
                // If we're closing a subquery, add a marker
                if (parenDepth > 0 && !subqueryStartPositions.isEmpty() && 
                    subqueryStartPositions.get(subqueryStartPositions.size() - 1) >= 0) {
                    tokens.add(new SOQLToken('SUBQUERY_END', SUBQUERY_MARKER));
                    subqueryStartPositions.remove(subqueryStartPositions.size() - 1);
                }
                
                tokens.add(new SOQLToken(String.valueOf(currentChar), CLOSE_PAREN));
                parenDepth = Math.max(0, parenDepth - 1);
                i++;
                continue;
            }
            
            // Handle operators and punctuation
            if (isOperatorOrPunctuation(currentChar)) {
                if (currentToken != '') {
                    tokens.add(new SOQLToken(currentToken, identifyTokenType(currentToken)));
                    currentToken = '';
                }
                
                // Check for multi-character operators (<=, >=, !=, etc.)
                if (i + 1 < soqlQuery.length() && 
                    isMultiCharOperator(currentChar, soqlQuery.substring(i + 1, i + 2))) {
                    tokens.add(new SOQLToken(soqlQuery.substring(i, i + 2), OPERATOR));
                    i += 2;
                } else {
                    tokens.add(new SOQLToken(currentChar, OPERATOR));
                    i++;
                }
                continue;
            }
            
            // Handle whitespace as delimiter
            if (currentChar.equals(' ')) {
                if (currentToken != '') {
                    tokens.add(new SOQLToken(currentToken, identifyTokenType(currentToken)));
                    currentToken = '';
                }
                i++;
                continue;
            }
            
            // Build current token
            currentToken += currentChar;
            i++;
        }
        
        // Add the last token if there is one
        if (currentToken != '') {
            tokens.add(new SOQLToken(currentToken, identifyTokenType(currentToken)));
        }
        
        // Process tokens to properly mark nested subqueries
        HelperSOQL.SOQLTokenList fullList = processNestedQueries(tokens);

        fullList.setClauseIndexes();
        return fullList;
    }
    
    /**
     * Helper method to check if a character is a letter or digit
     * @param c The character to check
     * @return Boolean indicating if the character is a letter or digit
     */
    private Boolean isLetterOrDigit(String c) {
        return c.isAlphaNumeric();
    }

    /**
     * Process tokens to properly structure nested queries
     * This helps with identification of query hierarchy
     * @param tokens The raw tokens from initial parsing
     * @return Processed tokens with subquery depth information
     */
     private SOQLTokenList processNestedQueries(SOQLTokenList tokens) {
        SOQLTokenList processedTokens = new SOQLTokenList();
        Stack subqueryStack = new Stack();
        Integer depth = 0;
        
        for (Integer i = 0; i < tokens.size(); i++) {
            SOQLToken token = tokens.get(i);
            
            // Skip the subquery markers as we'll handle them differently
            if (token.type == SUBQUERY_MARKER) {
                if (token.value == SUBQUERY_START) {
                    depth++;
                    subqueryStack.push(processedTokens.size() - 1); // Position of preceding OPEN_PAREN
                } else if (token.value == 'SUBQUERY_END') {
                    if (!subqueryStack.isEmpty()) {
                        Integer startPos = subqueryStack.pop();
                        // Tag tokens in this subquery with depth info
                        for (Integer j = startPos + 1; j < processedTokens.size(); j++) {
                            // Add subquery depth to the token type
                            processedTokens.get(j).type = 'SUBQUERY_' + depth + '_' + processedTokens.get(j).type;
                        }
                    }
                    depth = Math.max(0, depth - 1);
                }
                continue;
            }
            
            // Add to processed tokens
            processedTokens.add(token);
        }
        
        return processedTokens;
    }
    
    /**
     * Reassembles tokens back into a SOQL query
     * @param tokens List of tokens to reassemble
     * @return String of the reassembled SOQL query
     */
    public static String reassembleSOQL(SOQLTokenList tokens) {
        if (tokens == null || tokens.isEmpty()) {
            return '';
        }
        
        List<String> parts = new List<String>();
        String lastType = '';
        String lastValue = '';
        
        for (SOQLToken token : tokens.getTokens()) {
            String value = token.value;
            
            // Extract base type (remove subquery prefix if present)
            String type = token.type;
            if (type.startsWith('SUBQUERY_') && type.indexOf('_', 9) > 0) {
                // Extract the actual type part after the subquery depth marker
                type = type.substring(type.indexOf('_', 9) + 1);
            }
            
            // Handle spacing between tokens
            if (lastType != '' && 
                !lastType.equals(OPEN_PAREN) && 
                !type.equals(CLOSE_PAREN) &&
                !type.equals(OPERATOR) && 
                !lastType.equals(OPERATOR) &&
                !value.equals(',')) {
                
                // Special case for inner queries - ensure SELECT has space after opening paren
                if (lastValue.equals('(') && value.equalsIgnoreCase('SELECT')) {
                    parts.add(' ');
                }
                // Normal spacing between tokens
                else if (!lastValue.equals('(')) {
                    parts.add(' ');
                }
            }
            
            // Add token value
            parts.add(value);
            lastType = type;
            lastValue = value;
        }
        
        return String.join(parts, '');
    }
    
    /**
     * Identifies the type of a token based on its value
     * @param token The token value to identify
     * @return String representing the token type
     */
    private String identifyTokenType(String token) {
        // Convert to uppercase for case-insensitive comparison
        String upperToken = token.toUpperCase();
        
        // Check if token is a keyword
        if (HelperSOQL.keywords.contains(upperToken)) {
            return KEYWORD;
        }
        
        // Check if token is a function
        if (HelperSOQL.functions.contains(upperToken) || 
            (upperToken.endsWith('()') && functions.contains(upperToken.substring(0, upperToken.length() - 2)))) {
            return FUNCTION;
        }
        
        // Check if token is a number
        if (token.isNumeric()) {
            return NUMBR;
        }
        
        // Default to identifier (object or field name)
        return IDENTIFIER;
    }
    
    /**
     * Checks if a character is an operator or punctuation
     * @param c The character to check
     * @return Boolean indicating if the character is an operator or punctuation
     */
    private Boolean isOperatorOrPunctuation(String c) {
        String operators = '=<>!+-%*.,;:[]{}';
        return operators.indexOf(c) >= 0;
    }
    
    /**
     * Checks if two characters form a multi-character operator
     * @param first The first character
     * @param second The second character
     * @return Boolean indicating if the characters form a multi-character operator
     */
    private Boolean isMultiCharOperator(String first, String second) {
        String combined = first + second;
        Set<String> multiCharOps = new Set<String>{'<=', '>=', '!=', '<>', 'IN', 'OR', '**'};
        return multiCharOps.contains(combined);
    }

    //====================================================================================================
    // INNER CLASSES
    //====================================================================================================

    // Inner class to represent a stack for tracking subquery nesting
    private class Stack {
        private List<Integer> items = new List<Integer>();
        
        public void push(Integer item) {
            items.add(item);
        }
        
        public Integer pop() {
            if (items.isEmpty()) {
                return null;
            }
            Integer item = items.remove(items.size() - 1);
            return item;
        }
        
        public Integer peek() {
            if (items.isEmpty()) {
                return null;
            }
            return items.get(items.size() - 1);
        }
        
        public Boolean isEmpty() {
            return items.isEmpty();
        }
        
        public Integer size() {
            return items.size();
        }
    }
    
    /**
     * Represents a token in a SOQL query
     */
    public class SOQLToken {
        public String value;
        public String type;
        
        public SOQLToken(String value, String type) {
            this.value = value;
            this.type = type;
        }
        
        public override String toString() {
            return value;
        }
    }
    
    public class SOQLTokenList {

        public List<SOQLToken> tokens;
        public Integer orderIndex = -1;
        public Integer whereIndex = -1;
        public Integer usingIndex = -1;
        public Integer limitIndex = -1;
        public Integer mainObjectIndex = -1;

        public SOQLTokenList(List<SOQLToken> tokens) {
            this.tokens = tokens;
        }

        public SOQLTokenList() {
            this.tokens = new List<SOQLToken>();
        }

        public void setClauseIndexes()
        {
            for (Integer i = 0; i < tokens.size(); i++) {
                SOQLToken token = tokens.get(i);

                if (token.type == MAIN_OBJECT) {
                    mainObjectIndex = i;
                } else if (token.type == ORDER_BY) {
                    orderIndex = i;
                } else if (token.type == KEYWORD && token.value == 'WHERE') {
                    whereIndex = i;
                } else if (token.type == KEYWORD && token.value == 'USING') {
                    usingIndex = i;
                } else if (token.type == KEYWORD && token.value == 'LIMIT') {
                    limitIndex = i;
                }
            }
        }

        public List<SOQLToken> getTokens() {
            return tokens;
        }

        public Integer size() {
            return tokens.size();
        }

        public SOQLToken get(Integer index) {
            return tokens.get(index);
        }

        public void add(SOQLToken token) {
            //ensure ORDER is a keyword for the ORDER BY clause.
            if (token.type == KEYWORD && token.value == 'BY') {
                SOQLToken previousToken = getLastToken();
                if (previousToken != null && previousToken.type == IDENTIFIER && previousToken.value == 'ORDER') {
                    previousToken.type = ORDER_BY;
                }
            }

            
            //ensure we appropriately tag the main object
            SOQLToken lastToken = getLastToken();
            if (lastToken != null && lastToken.type == KEYWORD && lastToken.value.toUpperCase() == 'FROM') {
                token.type = MAIN_OBJECT; //ensure ORDER is a keyword
            }


            tokens.add(token);
        }

        public void add(Integer index, SOQLToken token) {
            if (index >= tokens.size())
                tokens.add(token);
            else {
                //ensure ORDER is a keyword for the ORDER BY clause.
                if (token.type == KEYWORD && token.value == 'BY') {
                    SOQLToken previousToken = get(index-1);
                    if (previousToken != null && previousToken.type == IDENTIFIER && previousToken.value == 'ORDER') {
                        previousToken.type = KEYWORD;
                    }
                }
                tokens.add(index, token);
            }
        }

        public SOQLToken getLastToken() {
            if (tokens.isEmpty()) {
                return null;
            }
            return tokens.get(tokens.size() - 1);
        }

        public void addAll(List<SOQLToken> newTokens) {
            tokens.addAll(newTokens);
        }

        public void clear() {
            tokens.clear();
        }

        public Boolean isEmpty() {
            return tokens.isEmpty();
        }

        public String createSOQL() {
            return HelperSOQL.reassembleSOQL(this);
        }

        public Boolean contains(String type, String value) {
            for (SOQLToken token : tokens) {
                if (token.type.equals(type) && token.value.equals(value)) {
                    return true;
                }
            }
            return false;
        }

        public Integer indexOf(String type, String value) {
            for (Integer i = 0; i < tokens.size(); i++) {
                SOQLToken token = tokens.get(i);
                if (token.type.equals(type) && token.value.equals(value)) {
                    return i;
                }
            }
            return -1;
        }

        public SOQLTokenList getTokens(Integer startIndex, Integer endIndex) {
            SOQLTokenList subset = new SOQLTokenList();
            for (Integer i = startIndex; i < endIndex; i++) {
                subset.add(tokens.get(i));
            }
            return subset;
        }

        public void replace(String type, String value, String newValue) {
            for (Integer i = 0; i < tokens.size(); i++) {
                SOQLToken token = tokens.get(i);
                if (token.type.equals(type) && token.value.equals(value)) {
                    token.value = newValue;
                }
            }
        }

        public void remove(Integer index) {
            SOQLToken token = tokens.get(index);
            if (token.type == ORDER_BY) {
                orderIndex = -1;
            } else if (token.type == KEYWORD && token.value == 'WHERE') {
                whereIndex = -1;
            } else if (token.type == KEYWORD && token.value == 'USING') {
                usingIndex = -1;
            } else if (token.type == KEYWORD && token.value == 'LIMIT') {
                limitIndex = -1;
            }

            tokens.remove(index);
        }

        public void removeFrom(Integer index) {
            for (Integer i = tokens.size() - 1; i >= index; i--) {
                tokens.remove(i);
            }
        }

        public String printTokens() {
            String debug = '';
            Integer index = 0;
            for (SOQLToken token : tokens) {
                debug += index + ' Type: ' + token.type + '                Token: ' + token.value + '\n';
                index++;
            }
            debug += '\nwhereIndex = ' + whereIndex + '\n';
            debug += 'usingIndex = ' + usingIndex + '\n';
            debug += 'limitIndex = ' + limitIndex + '\n';
            debug += 'orderIndex = ' + orderIndex + '\n';
            debug += 'mainObjectIndex = ' + mainObjectIndex + '\n';
            return debug;
        }

        public Boolean isAfter(String type, String value) {
            for (Integer i = 0; i < tokens.size(); i++) {
                SOQLToken token = tokens.get(i);
                if (token.type.equals(type) && token.value.equals(value)) {
                    return true;
                }
            }
            return false;
        }

        public Boolean isAfter(String type) {
            for (Integer i = 0; i < tokens.size(); i++) {
                SOQLToken token = tokens.get(i);
                if (token.type.equals(type)) {
                    return true;
                }
            }
            return false;
        }

        public Boolean isBefore(String type, String value) {
            for (Integer i = tokens.size() - 1; i >= 0; i--) {
                SOQLToken token = tokens.get(i);
                if (token.type.equals(type) && token.value.equals(value)) {
                    return false;
                }
            }
            return true;
        }

        public Boolean isBefore(String type) {
            for (Integer i = tokens.size() - 1; i >= 0; i--) {
                SOQLToken token = tokens.get(i);
                if (token.type.equals(type)) {
                    return false;
                }
            }
            return true;
        }

    }

}