Eventkaddy::Application.routes.draw do

  get 'surveys' => 'surveys#index'

  get 'surveys/:id' => 'surveys#show'

  get 'surveys/associations/:id' => 'surveys#associations'

  patch 'surveys/update_associations' => 'surveys#update_associations'

  get 'surveys/questions_order/:survey_section_id' => 'surveys#questions_order'

  patch 'surveys/update_questions_order' => 'surveys#update_questions_order'

  post 'surveys/upload_survey_response'

  get 'survey_wizard' => 'survey_wizard#survey_wizard'

  get 'survey_wizard/get_survey'

  get 'survey_wizard/get_survey_section'

  get 'survey_wizard/get_survey_sections'

  get 'survey_wizard/get_question'

  get 'survey_wizard/get_questions'

  get 'survey_wizard/get_answer'

  get 'survey_wizard/get_answers'

  get 'survey_wizard/get_hint'

  get 'survey_wizard/get_hints'

  post 'survey_wizard/save_survey'

  post 'survey_wizard/save_survey_section'

  post 'survey_wizard/save_question'

  post 'survey_wizard/save_answer'

  post 'survey_wizard/save_hint'

  # delete 'survey_wizard/delete_survey'
  delete 'survey_wizard/delete_survey_section'
  delete 'survey_wizard/delete_question'
  delete 'survey_wizard/delete_answer'
  delete 'survey_wizard/delete_hint'

end
