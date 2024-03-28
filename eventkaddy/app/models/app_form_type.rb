class AppFormType < ApplicationRecord
  has_many :app_submission_forms

  class << self
    def android
      find_by(name:"android")
    end

    def ios
      find_by(name:"ios")
    end
  end

end
