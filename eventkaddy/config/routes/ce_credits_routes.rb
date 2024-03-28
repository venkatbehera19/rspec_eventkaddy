Eventkaddy::Application.routes.draw do

  get 'ce_credits/get_reg_id'

  get 'download_ce_certificate'            => 'ce_credits#download_ce_certificate'
  patch 'ce_credits/generate_ce_certificate' => 'ce_credits#generate_ce_certificate'

  get 'download_avma2017_ce_certificates' => 'ce_credits#download_avma2017_ce_certificates'
  get 'download_avma2018_ce_certificates' => 'ce_credits#download_avma2018_ce_certificates'

  get 'download_acvs_ce_certificate'         => 'ce_credits#download_acvs_ce_certificate'
  get 'ce_credits/generate_acvs_certificate' => 'ce_credits#generate_acvs_certificate'
  get 'ce_credits/generate_acvs_certificate_remote' => 'ce_credits#generate_acvs_certificate_remote'

  get 'ce_credits/generate_motm_apa_main_conference_pdf'   => 'ce_credits#generate_motm_apa_main_conference_pdf'
  get 'ce_credits/generate_motm_apa_saturday_pdf'          => 'ce_credits#generate_motm_apa_saturday_pdf'
  get 'ce_credits/generate_motm_apa_sunday_pdf'            => 'ce_credits#generate_motm_apa_sunday_pdf'
  get 'ce_credits/generate_motm_apa_wednesday_pdf'         => 'ce_credits#generate_motm_apa_wednesday_pdf'

  get 'ce_credits/generate_motm_ihrm_main_conference_pdf' => 'ce_credits#generate_motm_ihrm_main_conference_pdf'
  get 'ce_credits/generate_motm_ihrm_saturday_pdf'        => 'ce_credits#generate_motm_ihrm_saturday_pdf'
  get 'ce_credits/generate_motm_ihrm_sunday_pdf'          => 'ce_credits#generate_motm_ihrm_sunday_pdf'
  get 'ce_credits/generate_motm_ihrm_wednesday_pdf'       => 'ce_credits#generate_motm_ihrm_wednesday_pdf'

  get 'ce_credits/generate_motm_shrm_main_conference_pdf'  => 'ce_credits#generate_motm_shrm_main_conference_pdf'
  get 'ce_credits/generate_motm_nasba_main_conference_pdf' => 'ce_credits#generate_motm_nasba_main_conference_pdf'

  get 'download_mte_ce_certificate'         => 'ce_credits#download_mte_ce_certificate'
  get 'ce_credits/generate_mte_certificate' => 'ce_credits#generate_mte_certificate'
  get 'ce_credits/generate_mte_certificate_remote' => 'ce_credits#generate_mte_certificate_remote'

  get 'ce_credits/generate_fiserv_certificate_pdf' => 'ce_credits#generate_fiserv_certificate_pdf'

  get 'email_ce_certificate'   => 'ce_credits#email_ce_certificate'
  get 'email_acvs_certificate' => 'ce_credits#email_acvs_certificate'
  get 'email_mte_certificate'  => 'ce_credits#email_mte_certificate'

  put 'ce_credits/generate_ce_sessions_pdf_report_cms' => 'ce_credits#generate_ce_sessions_pdf_report_cms'

  get 'ce_credits/event_78_generate_certificate_of_attendance' => 'ce_credits#event_78_generate_certificate_of_attendance'
 
  get 'ce_credits/event_78_generate_detailed_continuing_education_certificate' => 'ce_credits#event_78_generate_detailed_continuing_education_certificate'

  get 'ce_credits/event_107_generate_attendance_certificate' => 'ce_credits#event_107_generate_attendance_certificate'

  get 'ce_credits/event_114_generate_risk_intelligence_certificate' => 'ce_credits#event_114_generate_risk_intelligence_certificate'

  get 'ce_credits/event_126_generate_aap_documentation_of_attendance' => 'ce_credits#event_126_generate_aap_documentation_of_attendance'

  get 'ce_credits/event_119_generate_bcbs_certificate_of_completion' => 'ce_credits#event_119_generate_bcbs_certificate_of_completion'

  get 'ce_credits/event_118_generate_certificate_of_attendance' => 'ce_credits#event_118_generate_certificate_of_attendance'

  get 'ce_credits/event_118_generate_detailed_certificate_of_attendance' => 'ce_credits#event_118_generate_detailed_certificate_of_attendance'

  get 'ce_credits/event_134_generate_fiserv_cpe_credit_certificate' => 'ce_credits#event_134_generate_fiserv_cpe_credit_certificate'

  get 'ce_credits/event_122_generate_certificate_of_attendance' => 'ce_credits#event_122_generate_certificate_of_attendance'

  get 'ce_credits/event_122_generate_detailed_continuing_education_certificate' => 'ce_credits#event_122_generate_detailed_continuing_education_certificate'

  get 'ce_credits/event_161_generate_bcbs_certificate_of_completion' => 'ce_credits#event_161_generate_bcbs_certificate_of_completion'

  get 'ce_credits/event_158_generate_certificate_of_attendance' => 'ce_credits#event_158_generate_certificate_of_attendance'

  get 'ce_credits/event_158_generate_detailed_certificate_of_attendance' => 'ce_credits#event_158_generate_detailed_certificate_of_attendance'

  get 'ce_credits/event_182_generate_fiserv_cpe_credit_certificate' => 'ce_credits#event_182_generate_fiserv_cpe_credit_certificate'

  get 'ce_credits/event_181_generate_certificate_of_completion' => 'ce_credits#event_181_generate_certificate_of_completion'

  get 'ce_credits/event_187_generate_certificate_of_attendance' => 'ce_credits#event_187_generate_certificate_of_attendance'

  get 'ce_credits/event_187_generate_detailed_continuing_education_certificate' => 'ce_credits#event_187_generate_detailed_continuing_education_certificate'

  get 'ce_credits/event_205_generate_certificate_of_completion' => 'ce_credits#event_205_generate_certificate_of_completion'

  get 'ce_credits/event_214_generate_cpe_certificate' => 'ce_credits#event_214_generate_cpe_certificate'

  get 'ce_credits/event_227_generate_certificate_of_completion' => 'ce_credits#event_227_generate_certificate_of_completion'

  get 'ce_credits/event_208_generate_certificate_of_attendance' => 'ce_credits#event_208_generate_certificate_of_attendance'

  get 'ce_credits/event_208_generate_detailed_certificate_of_attendance' => 'ce_credits#event_208_generate_detailed_certificate_of_attendance'

  get 'ce_credits/event_201_generate_certificate_of_attendance' => 'ce_credits#event_201_generate_certificate_of_attendance'

  get 'ce_credits/event_201_generate_detailed_continuing_education_certificate' => 'ce_credits#event_201_generate_detailed_continuing_education_certificate'

  get 'ce_credits/event_247_generate_certificate_of_attendance' => 'ce_credits#event_247_generate_certificate_of_attendance'

  get 'ce_credits/event_247_generate_detailed_continuing_education_certificate' => 'ce_credits#event_247_generate_detailed_continuing_education_certificate'

  get 'ce_credits/event_240_generate_certificate_of_completion' => 'ce_credits#event_240_generate_certificate_of_completion'

  get 'ce_credits/event_267_generate_certificate_of_completion' => 'ce_credits#event_267_generate_certificate_of_completion'

  get 'ce_credits/event_263_generate_certificate_of_attendance' => 'ce_credits#event_263_generate_certificate_of_attendance'

  get 'ce_credits/event_263_generate_certificate_of_completion' => 'ce_credits#event_263_generate_certificate_of_completion'

  get 'ce_credits/event_263_generate_xyz' => 'ce_credits#event_263_generate_xyz'

  get 'ce_credits/event_263_generate_certificate_of_test' => 'ce_credits#event_263_generate_certificate_of_test'

  get 'ce_credits/event_263_generate_certificate_of_attendance001' => 'ce_credits#event_263_generate_certificate_of_attendance001'

  get 'ce_credits/event_268_generate_certificate_of_attendance' => 'ce_credits#event_268_generate_certificate_of_attendance'

  get 'ce_credits/event_269_generate_the_main_certificate' => 'ce_credits#event_269_generate_the_main_certificate'

  get 'ce_credits/event_269_generate_test_certificate_3' => 'ce_credits#event_269_generate_test_certificate_3'

  get 'ce_credits/event_269_generate_test_cerificate' => 'ce_credits#event_269_generate_test_cerificate'

  get 'ce_credits/event_269_generate_test_cerificate_4' => 'ce_credits#event_269_generate_test_cerificate_4'

  get 'ce_credits/event_269_generate_test_certificate_5' => 'ce_credits#event_269_generate_test_certificate_5'

  get 'ce_credits/event_269_generate_test__4' => 'ce_credits#event_269_generate_test__4'

  get 'ce_credits/event_269_generate_certificate_of_survey_completion' => 'ce_credits#event_269_generate_certificate_of_survey_completion'

  get 'ce_credits/event_292_generate_sdafp_certificate_of_attendance' => 'ce_credits#event_292_generate_sdafp_certificate_of_attendance'

  get 'ce_credits/event_293_generate_certificate_of_attendance' => 'ce_credits#event_293_generate_certificate_of_attendance'

  get 'ce_credits/event_293_generate_detailed_ce_certificate' => 'ce_credits#event_293_generate_detailed_ce_certificate'

  get 'ce_credits/event_304_generate_certificate_of_attendance_2019' => 'ce_credits#event_304_generate_certificate_of_attendance_2019'

  get 'ce_credits/event_304_generate_certificate_of_completion' => 'ce_credits#event_304_generate_certificate_of_completion'

  get 'ce_credits/event_322_generate_certificate_of_attendance_2019' => 'ce_credits#event_322_generate_certificate_of_attendance_2019'

  get 'ce_credits/event_314_generate_certificate_of_completion' => 'ce_credits#event_314_generate_certificate_of_completion'

end
