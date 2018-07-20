require 'csv'

require_relative 'ballot'
require_relative 'commands'


candidates_to_elect = ARGV[0]
if candidates_to_elect.nil?
	candidates_to_elect = 1
end

ballot_type = 'pr'
header = true

ballots_raw = CSV.read("n_bn.csv")
ballot = Ballot.new(ballots_raw,header,ballot_type,candidates_to_elect)
puts
puts
puts "There are #{ballot.total_votes} ballots."
puts "There are #{ballot.formal_votes} formal ballots"
puts "There are #{ballot.candidates.count} candidates"
puts

#check first preference votes
# print_first_preference(ballot)

# if ['opv','cpv'].include? ballot_type
# 	check_for_winner(ballot)
# 	puts 'no'
# end

print_current_votes(ballot)

round = 0
until ballot.has_winner || ballot.candidates_elected == ballot.candidates_to_elect
	puts "** ROUND #{round} **"

	elected = check_for_elected(ballot,round)

	if ballot.candidates_elected == ballot.candidates_to_elect
		break
	end

	if elected.count > 0
		elected.each do |e|
			distribute_votes(ballot,round,e)
			print_current_votes(ballot)
		end
	else
		lowest = find_lowest(ballot)
		distribute_votes(ballot,round,lowest)
		print_current_votes(ballot)
	end
	round += 1
end
