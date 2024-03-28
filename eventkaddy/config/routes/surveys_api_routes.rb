Eventkaddy::Application.routes.draw do

  get 'surveys_api/get_single_survey'

  get 'surveys_api/survey_results'

  post 'surveys_api/post_survey_response' => 'surveys_api#post_survey_response'

end