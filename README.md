I have edided this version of mongoid to add the method "as_document" to support has_many relationships

Without this change, the error "undefined method as_document for array" will be returned when the following is called: 

    @person.as_document

If @person has_many children
