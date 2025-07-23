puts "Deleting DB"
Move.destroy_all
Round.destroy_all
Scoresheet.destroy_all
SessionPlayer.destroy_all
GameSession.destroy_all
Game.destroy_all
User.destroy_all
puts "DB deleted"

puts "Creating games"
Game.create!(title: "Generic score counter", description:"Set your own rules!")
Game.create!(title: "Generic bet manager", description:"Set your own rules!")
Game.create!(title: "Skyjo", description:"Don't be the first to reach 100!")
Game.create!(title: "Five Crowns", description:"11 rounds of combinations!")
Game.create!(title: "Koi Koi", description:"You filthy weeb!")
Game.create!(title: "Oh Hell (Escalier)", description:"The power of my hand is over 9000 and I'll prove it!")
Game.create!(title: "Killer", description:"TODO")
Game.create!(title: "Azul", description:"The prettiest game!")
Game.create!(title: "Poker", description:"Gimme your money!")
Game.create!(title: "Scopa", description:"Because sometimes, you wanna feel like a Godfather!")
puts "Created #{Game.count} games"

puts "Creating users"
User.create(first_name: "Esther", last_name: "Descamps", username: "Tether", email: "esther@mail.com", password: "password")
User.create(first_name: "Flore", last_name: "Capelier", username: "Florette", email: "flore@mail.com", password: "password")
User.create(first_name: "Renaud", last_name: "Torrent", username: "Reno", email: "renaud@mail.com", password: "password")
User.create(first_name: "Anne-Laure", last_name: "Crépel", username: "Doudou", email: "anne-laure@mail.com", password: "password")
User.create(first_name: "Mara", last_name: "Goyet", username: "Môman", email: "mara@mail.com", password: "password")
User.create(first_name: "Claude", last_name: "Capelier", username: "Pôpa", email: "claude@mail.com", password: "password")
User.create(first_name: "Jonas", last_name: "Capelier", username: "Joe", email: "jonas@mail.com", password: "password")
puts "Created #{User.count} users"
