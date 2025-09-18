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
Game.create!(title: "Oh Hell", description:"The power of my hand is over 9000 and I'll prove it!")
Game.create!(title: "Mexican Train", description:"Because a game should last at least four hours!")
Game.create!(title: "Azul", description:"The prettiest game!")
Game.create!(title: "Poker", description:"Gimme your money!")
Game.create!(title: "Scopa", description:"Because sometimes, you wanna feel like a Godfather!")
puts "Created #{Game.count} games"

puts "Creating users"
User.create(username: "Tether", email: "esther@mail.com", password: "password")
User.create(username: "Florette", email: "flore@mail.com", password: "password")
User.create(username: "Reno", email: "renaud@mail.com", password: "password", admin: true)
User.create(username: "<3 Doudou <3", email: "anne-laure@mail.com", password: "password")
User.create(username: "Môman", email: "mara@mail.com", password: "password")
User.create(username: "Pôpa", email: "claude@mail.com", password: "password")
User.create(username: "Joe", email: "jonas@mail.com", password: "password")
puts "Created #{User.count} users"
