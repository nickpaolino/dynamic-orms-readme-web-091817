require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class Song

  def self.table_name # Creates the table name for SQL
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  self.column_names.each do |col_name| # Setting up an attribute accessor for each column name
    attr_accessor col_name.to_sym
  end

  # accessors are nil here

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value) # Assigns each value to a method that was
      # defined by the accessor and by assigning it to the writer method, it
      # creates an instance variable
    end
  end

  # accessors have values

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil? # unless there's no value in the accessor
      # from the column name
    end
    values.join(", ")
    # ""Nick", 23"
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    # This turns ["id", "name", "album"] into "name, album"
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end

song = Song.new
song.values_for_insert
