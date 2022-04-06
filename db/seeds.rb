# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ApplicationRecord.transaction do
  puts "Destroying existing records and resetting primary keys..."

  # Unnecessary if using `rails db:seed:replant`
  Follow.destroy_all
  Tweet.destroy_all
  User.destroy_all

  # Reset the primary key of each table to start at 1 again
  %w(mentions follows tweets users).each do |table_name|
    ApplicationRecord.connection.reset_pk_sequence!(table_name)
  end


  puts "Generating users..."
  users = 40.times.map do
    username = Faker::FunnyName.unique.name.parameterize(separator: "_")
    User.create!(username:, password: "password")
  end

  # Find more here: https://github.com/faker-ruby/faker
  quote_sources = [
    -> { Faker::Quotes::Shakespeare.hamlet_quote },
    -> { Faker::Quotes::Shakespeare.as_you_like_it_quote },
    -> { Faker::Quotes::Shakespeare.king_richard_iii_quote },
    -> { Faker::Quotes::Shakespeare.romeo_and_juliet_quote },
    -> { Faker::Quote.yoda },
    -> { Faker::GreekPhilosophers.quote },
    -> { Faker::TvShows::DrWho.quote },
    -> { Faker::Movies::HitchhikersGuideToTheGalaxy.quote },
  ]

  puts "Generating tweets and mentions..."
  users.each do |user|
    user.following = users.reject { |u| u == user }.sample(4)

    15.times do |idx|
      tweet = user.tweets.create!(
        body: quote_sources.sample.call[0...280], 
        created_at: rand(365).days.ago,
        mentioned_user_id: users.sample.id
      )
    end
  end

  puts "Done"
end