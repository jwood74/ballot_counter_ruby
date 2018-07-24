require 'csv'

require_relative 'ballot'
require_relative 'commands'

candidates_to_elect = ARGV[0]
if candidates_to_elect.nil?
	candidates_to_elect = 1
end

ballot_type = 'pr'
header_row = 1
gender_row = 2
age_row = 3

ballots_raw = CSV.read("s_dickson.csv")

ballot = Ballot.new(ballots_raw,header_row,gender_row,age_row,ballot_type,candidates_to_elect)
puts
puts
puts "There are #{ballot.total_votes} ballots."
puts "There are #{ballot.formal_votes} formal ballots"
puts "There are #{ballot.candidates.count} candidates"
puts

ballot.female_needed = 4
ballot.young_labor_needed = 1

#check first preference votes
# print_first_preference(ballot)

# if ['opv','cpv'].include? ballot_type
# 	check_for_winner(ballot)
# 	puts 'no'
# end

# print_current_votes(ballot)

round = 1
until ballot.has_winner || ballot.candidates_elected == ballot.candidates_to_elect
	puts "** ROUND #{round} **"

	elected = check_for_elected(ballot,round)

	if ballot.candidates_elected == ballot.candidates_to_elect
		break
	end

	check_for_aa(ballot)

	unless round == 1

		distribute = who_to_distribute(ballot)

		distribute_votes(ballot,round,distribute)

	end

	print_current_votes(ballot)


	# if elected.count > 0
	# 	elected.each do |e|
	# 		distribute_votes(ballot,round,e)
	# 		print_current_votes(ballot)
	# 		check_for_aa(ballot)
	# 	end
	# else
	# 	lowest = find_lowest(ballot)
	# 	distribute_votes(ballot,round,lowest)
	# 	check_for_aa(ballot)
	# 	print_current_votes(ballot)
	# end
	round += 1
end

display_final_result(ballot)