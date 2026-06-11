#!/bin/bash

get_tc_desc() { eval "echo \"\$TC_DESC_$1\""; }
get_tc_priority() { local v; eval "v=\$TC_PRI_$1"; echo "${v:-P2}"; }
get_tc_category() { local v; eval "v=\$TC_CAT_$1"; echo "${v:-Other}"; }
get_tc_cat_class() { local v; eval "v=\$TC_CLS_$1"; echo "${v:-home}"; }

TC_DESC_TC01="Verify the language selection screen loads correctly with all supported language options and the start button is accessible."
TC_DESC_TC02="Validate that selecting a language persists and navigates the user to the next onboarding step."
TC_DESC_TC03="Verify the alternate onboarding path where the user skips entering their name and proceeds to the home feed."
TC_DESC_TC04="Validate entering a display name during onboarding and confirm navigation to the home feed with the name saved."
TC_DESC_TC05="Grant location permission via the weather widget interstitial and verify that home feed content cards load."
TC_DESC_TC06="End-to-end chat flow: type a farming question, wait for AI response, and tap a related follow-up question."
TC_DESC_TC07="Tap the Learn More action on a home feed card and verify the full advice detail view opens."
TC_DESC_TC08="Verify the full advice screen displays content correctly and shows related questions for further exploration."
TC_DESC_TC09="Interact with the first onboarding question card on the home feed by selecting an answer and confirming."
TC_DESC_TC10="Assert the gender selection card is present on the home feed with all expected options without interacting."
TC_DESC_TC11="Upload a crop disease image from the gallery and verify the AI returns a relevant agricultural diagnosis."
TC_DESC_TC12="Assert the crops selection card is present on the home feed with expected crop options without interacting."
TC_DESC_TC13="Type a question, receive an AI response, and verify the share functionality works correctly."
TC_DESC_TC14="Validate the text-to-speech playback of an AI response by tapping the listen button and verifying audio controls."
TC_DESC_TC15="Verify toggling between Day, Night, and Auto display modes in the settings screen."
TC_DESC_TC16="Update the user display name in settings and verify the change is saved and reflected."
TC_DESC_TC17="Complete the phone number sign-up flow from the settings screen with OTP verification."
TC_DESC_TC18="Verify the user can skip the sign-up prompt from settings and return to the previous screen."
TC_DESC_TC19="Complete the phone number sign-up flow triggered from the navigation drawer."
TC_DESC_TC20="Open the Help and Support section and verify FAQ accordion items expand and collapse correctly."
TC_DESC_TC21="Navigate to and verify the Terms of Use content is displayed correctly from the Help section."
TC_DESC_TC22="Navigate to and verify the Privacy Policy content is displayed correctly from the Help section."
TC_DESC_TC23="Change the app language from the navigation drawer and verify the language switch takes effect."
TC_DESC_TC24="Verify the voice input speak button is visible and accessible in the chat input area."
TC_DESC_TC25="Full login flow: enter phone number, receive OTP, verify, and confirm successful authentication."
TC_DESC_TC26="Navigate to chat history, verify past conversations are listed, and open a previous conversation."
TC_DESC_TC27="Perform logout from the settings screen and verify redirect to the language selection screen."
TC_DESC_TC28="Tap the save button on an AI response and verify the save button remains accessible."
TC_DESC_TC29="Verify the alternate path where the user taps Skip instead of granting location access."
TC_DESC_TC30="Tap the close button in the chat screen and verify navigation back to the home feed."
TC_DESC_TC31="Tap the Terms of Use link on the language selection screen and verify the legal dialog opens."
TC_DESC_TC32="Tap the Privacy Policy link on the language selection screen and verify the legal dialog opens."
TC_DESC_TC33="Open the navigation drawer and verify recent chat items are displayed with correct titles."
TC_DESC_TC34="Validate the camera capture flow by taking a photo and sending it as a query to the AI."
TC_DESC_TC35="After an initial AI response, type a follow-up question and verify contextual AI response."
TC_DESC_TC36="Tap the Home option in the navigation drawer and verify navigation to the home feed screen."
TC_DESC_TC37="Open a legal dialog from the app and verify it can be properly dismissed and closed."
TC_DESC_TC38="Simulate airplane mode to trigger the no-internet error screen and verify the Try Again recovery flow."
TC_DESC_TC39="Trigger a chat error state by disabling network mid-conversation and verify the inline retry action works."
TC_DESC_TC40="Verify the chat history retry mechanism when network is temporarily unavailable."

for tc in TC01 TC02 TC03 TC04 TC31 TC32 TC37; do eval "TC_CAT_$tc=Onboarding; TC_CLS_$tc=onboarding"; done
for tc in TC05 TC07 TC08 TC09 TC10 TC12; do eval "TC_CAT_$tc=Home; TC_CLS_$tc=home"; done
for tc in TC06 TC11 TC13 TC14 TC24 TC26 TC28 TC30 TC34 TC35; do eval "TC_CAT_$tc=Chat; TC_CLS_$tc=chat"; done
for tc in TC15 TC16 TC18 TC27; do eval "TC_CAT_$tc=Settings; TC_CLS_$tc=settings"; done
for tc in TC17 TC19 TC25; do eval "TC_CAT_$tc=Auth; TC_CLS_$tc=auth"; done
for tc in TC20 TC21 TC22; do eval "TC_CAT_$tc=Help; TC_CLS_$tc=help"; done
for tc in TC23 TC29 TC33 TC36; do eval "TC_CAT_$tc=Navigation; TC_CLS_$tc=navigation"; done
for tc in TC38 TC39 TC40; do eval "TC_CAT_$tc=Error; TC_CLS_$tc=error"; done

for tc in TC01 TC02 TC04 TC05 TC06 TC11 TC17 TC19 TC25 TC26 TC27 TC34 TC38 TC39; do eval "TC_PRI_$tc=P0"; done
for tc in TC03 TC07 TC08 TC09 TC10 TC12 TC13 TC14 TC16 TC23 TC28 TC29 TC30 TC33 TC35 TC40; do eval "TC_PRI_$tc=P1"; done
for tc in TC15 TC18 TC20 TC21 TC22 TC24 TC31 TC32 TC36 TC37; do eval "TC_PRI_$tc=P2"; done
