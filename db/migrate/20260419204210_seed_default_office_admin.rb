require "digest"
require "securerandom"

class SeedDefaultOfficeAdmin < ActiveRecord::Migration[8.1]
  class MigrationOffice < ApplicationRecord
    self.table_name = "offices"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    office = MigrationOffice.find_or_create_by!(slug: "default") do |item|
      item.name = ENV.fetch("OFFICE_NAME", "Kayran Advocacia")
    end

    email = ENV.fetch("ADMIN_EMAIL", "admin@matrizjuridica.com").downcase
    password = ENV.fetch("ADMIN_PASSWORD", "admin123")
    salt = SecureRandom.hex(16)
    digest = Digest::SHA256.hexdigest("#{salt}--#{password}")

    MigrationUser.find_or_create_by!(office_id: office.id, email: email) do |user|
      user.name = "Administrador"
      user.role = "admin"
      user.active = true
      user.password_salt = salt
      user.password_digest = digest
    end
  end

  def down
    email = ENV.fetch("ADMIN_EMAIL", "admin@matrizjuridica.com").downcase
    MigrationUser.where(email: email).delete_all
  end
end
