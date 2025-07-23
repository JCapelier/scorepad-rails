puts "Deleting DB"
UserStat.destroy_all
Move.destroy_all
Round.destroy_all
ScoreSheet.destroy_all
SessionPlayer.destroy_all
GameSession.destroy_all
Game.destroy_all
User.destroy_all
puts "DB deleted"

puts "Creating games"
Game.create!(title: "Generic score counter")
Game.create!(title: "Generic bet manager")
Game.create!(title: "Skyjo")
Game.create!(title: "Five Crowns")
Game.create!(title: "Koi Koi")
Game.create!(title: "Oh Hell (Escalier)")
Game.create!(title: "Killer")
Game.create!(title: "Azul")
Game.create!(title: "Poker")
Game.create!(title: "Scopa")
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
