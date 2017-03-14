	def readFile(name)
        puts name.kind_of?(Array)
        splitted = name.split(/\s-r\s/)
		art = IO.readlines(splitted[1])
        art.map! do |x|
            x = "#{splitted[0]} " +x
        end
        puts art.kind_of?(Array)
        puts art.size
        puts art
	end

    readFile("-M -r art.txt")