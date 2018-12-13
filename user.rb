require 'data_mapper' # metagem, requires common plugins too.

class User
    include DataMapper::Resource
    property :id, Serial
    property :first_name, String
    property :last_name, String
    property :email, String
    property :password, String
    property :created_at, DateTime
    property :administrator, Boolean, :default => false
    property :pro, Boolean, :default => false
    property :student, Boolean, :default => false
    property :tutor, Boolean, :default => false
    property :description, Text
    property :tag1, Text
    property :tag2, Text
    property :tag3, Text
    property :city, String
    property :state, String

    def login(password)
        return self.password == password
    end
end