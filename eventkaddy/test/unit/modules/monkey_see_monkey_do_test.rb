require 'test_helper'

class MonkeySeeMonkeyDoTest < ActiveSupport::TestCase

  def survey_schema
    Survey.find(224).schema 20
  end

  def test_copy_model_to_event

    assert Survey.find(224).questions.length > 0, "questions exist in test db"
    assert Survey.find(224).questions.first.answers.length > 0, "answers exist in test db"

    result = MonkeySeeMonkeyDo.copy_model_to_event(survey_schema)

    assert result[:model].is_a?(Survey)
    assert_equal result[:model].attributes["event_id"], 20, "new event_id merged"
    assert_equal result[:model].attributes["id"], nil, "id should be nil (so new record will be saved)"

    assert result[:children].length > 0, "did anything with children"

    first_section = result[:children][0]
    assert       first_section[:model].is_a?(SurveySection), "first child is a survey section"
    assert_equal first_section[:model].attributes["event_id"], 20, "new event_id merged"
    assert_equal first_section[:model].attributes["id"], nil, "id should be nil (so new record will be saved)"
    assert_nil   first_section[:model].attributes["survey_id"], "there is no old survey_id"
    assert_nil   first_section[:model].attributes["survey_section_id"], "there is no old survey_id"
    # puts first_section[:model].inspect.red

    # questions
    # it is possible for a survey section to have no children, as demonstrated here...
    # that's not actually the implementation failing, but our test not accounting for it
    # is this worth concerning myself over?
    first_question = result[:children][1][:children][0]
    assert       first_question[:model].is_a?(Question), "first child is a question"
    assert_equal first_question[:model].attributes["event_id"], 20, "new event_id merged"
    assert_equal first_question[:model].attributes["id"], nil, "id should be nil (so new record will be saved)"
    assert_nil   first_question[:model].attributes["survey_id"], "there is no old survey_id"
    assert_nil   first_question[:model].attributes["survey_section_id"], "there is no old survey_id" # failing
    puts first_question[:model].inspect.red

    # answers
    first_answer = first_question[:children][0]
    assert       first_answer[:model].is_a?(Answer)
    assert_equal first_answer[:model].attributes["event_id"], 20, "new event_id merged"
    assert_equal first_answer[:model].attributes["id"], nil, "id should be nil (so new record will be saved)"
    assert_nil   first_answer[:model].attributes["question_id"], "no old question_id"
    # when do we copy survey_id into the child? can't do it unless we save, but
    # then we don't get to preview the new id we want to save is right... I
    # guess that's okay though. We can just do that as a separate step with the
    # result of this function

    # raise for specifying columns, as that feature is not implemented
    assert_raise RuntimeError do
      MonkeySeeMonkeyDo.copy_model_to_event({columns: [:blah, :bloo] })
    end
  end

  def test_save_result_copy
    result = MonkeySeeMonkeyDo.save_result_copy( MonkeySeeMonkeyDo.copy_model_to_event(survey_schema) )

    # raise result.inspect.yellow

    assert result[:model].is_a?(Survey)
    assert_equal result[:model].attributes["event_id"], 20, "new event_id merged"
    assert_not_nil result[:model].attributes["id"]

    first_section = result[:children][1] # actually second section, but first one has no questions
    assert           first_section[:model].is_a?(SurveySection), "first child is a survey question"
    assert_equal     first_section[:model].attributes["event_id"], 20, "new event_id merged"
    assert_not_nil   first_section[:model].attributes["id"]
    assert_not_nil   first_section[:model].attributes["survey_id"]
    assert_not_equal first_section[:model].attributes["survey_id"], 224, "has a new survey_id"
    # puts first_section[:model].inspect.green

    first_question = first_section[:children][0] # says that this is nil
    assert           first_question[:model].is_a?(Question), "first child is a question"
    assert_equal     first_question[:model].attributes["event_id"], 20, "new event_id merged"
    assert_not_nil   first_question[:model].attributes["id"]
    assert_not_nil   first_question[:model].attributes["survey_id"]
    assert_not_equal first_question[:model].attributes["survey_id"], 224, "has a new survey_id"
    puts first_question[:model].inspect.green

    first_answer = first_question[:children][0]
    assert         first_answer[:model].is_a?(Answer)
    assert_equal   first_answer[:model].attributes["event_id"], 20, "new event_id merged"
    assert_not_nil first_answer[:model].attributes["id"]
    assert_not_nil first_answer[:model].attributes["question_id"]
  end

end
