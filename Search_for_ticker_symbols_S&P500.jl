#==
Automatically Search for Ticker Symbols of the S&P500
Author©: Erwin Jentzsch
Date: March 2026
==#

using HTTP, Gumbo, Cascadia, DataFrames, CSV

url = "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"

#= String(HTTP.get(url).body): 
    - HTTP.get(url):    sends a request to the website
    - .body:            contains the raw HTML code
    - String():         converts the response into text
=#
html = String(HTTP.get(url).body)
#=
parsedhtml converts the string into an object with a usable structure
=#
parsed = parsehtml(html)

#=
eachmatch(Selector("table.wikitable"), parsed.root)[1]:
    - eachmatch(..., parsed.root): searches the structured object and parsed root scans the entire webpage
    - Selector("table.wikitable"): search for tables
    - [1]:                         take the first table (the S&P500 list is the first table on the page)
=#
table = eachmatch(Selector("table.wikitable"), parsed.root)[1]

#=
eachmatch(Selector("tr"), table):
    - we search through all rows within the table
=#
rows = eachmatch(Selector("tr"), table)

# create empty object
data = []

#=
for row in rows[2:end]                                  -->  loop over all table rows 
    cols = eachmatch(Selector("td"), row)               -->  searches each row for td (table data)
    if length(cols) > 0                                 -->  row should contain data
        push!(data, [strip(text(c)) for c in cols])     --> cols are td elements and we extract the text and store it in an array (data) consisting of the respective rows
    end
end
=#
for row in rows[2:end]  # first row = header
    cols = eachmatch(Selector("td"), row)
    if length(cols) > 0
        push!(data, [strip(text(c)) for c in cols])
    end
end

#=
DataFrame(reduce(vcat, permutedims.(data)), Symbol.(headers)):
    - permutedims.(data):   converts each row into a 1xn matrix
    - reduce(vcat, ...):    combines all rows to build a matrix
    - Symbol.(headers):     converts strings into column names
=#
df = DataFrame(reduce(vcat, permutedims.(data)), Symbol.(headers))

# save CSV file
CSV.write("sp500.csv", df)

# filter that searches for a company
filter(row -> startswith(lowercase(row.Security), "tesla"), df)