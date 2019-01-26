module Layout exposing (Page(..), frame)

import Data.Session as Session exposing (Session)
import Html exposing (..)
import Html.Attributes
    exposing
        ( attribute
        , class
        , classList
        , href
        , id
        , placeholder
        , rel
        , selected
        , target
        , type_
        , value
        )
import Html.Events as Events
import Route exposing (Route)


{-| Used to highlight current page in navbar.
-}
type Page
    = Other
    | Mailbox
    | Monitor
    | Status


type alias FrameControls msg =
    { viewMailbox : String -> msg
    , mailboxOnInput : String -> msg
    , mailboxValue : String
    , recentOptions : List String
    , recentActive : String
    , clearFlash : msg
    , showMenu : Bool
    , toggleMenu : msg
    }


frame : FrameControls msg -> Session -> Page -> Maybe (Html msg) -> List (Html msg) -> Html msg
frame controls session activePage modal content =
    div [ class "app" ]
        [ header []
            [ nav [ class "navbar" ]
                [ span [ class "navbar-toggle", Events.onClick controls.toggleMenu ]
                    [ i [ class "fas fa-bars" ] [] ]
                , span [ class "navbar-brand" ]
                    [ a [ Route.href Route.Home ] [ text "@ inbucket" ] ]
                , ul [ classList [ ( "main-nav", True ), ( "active", controls.showMenu ) ] ]
                    [ li [ class "navbar-mailbox" ]
                        [ form [ Events.onSubmit (controls.viewMailbox controls.mailboxValue) ]
                            [ input
                                [ type_ "text"
                                , placeholder "mailbox"
                                , value controls.mailboxValue
                                , Events.onInput controls.mailboxOnInput
                                ]
                                []
                            ]
                        ]
                    , if session.config.monitorVisible then
                        navbarLink Monitor Route.Monitor [ text "Monitor" ] activePage

                      else
                        text ""
                    , navbarLink Status Route.Status [ text "Status" ] activePage
                    , navbarRecent activePage controls
                    ]
                ]
            ]
        , div [ class "navbar-bg" ] [ text "" ]
        , frameModal modal
        , div [ class "page" ] ([ errorFlash controls session.flash ] ++ content)
        , footer []
            [ div [ class "footer" ]
                [ externalLink "https://www.inbucket.org" "Inbucket"
                , text " is an open source projected hosted at "
                , externalLink "https://github.com/jhillyerd/inbucket" "GitHub"
                , text "."
                ]
            ]
        ]


frameModal : Maybe (Html msg) -> Html msg
frameModal maybeModal =
    case maybeModal of
        Just modal ->
            div [ class "modal-mask" ]
                [ div [ class "modal well" ] [ modal ]
                ]

        Nothing ->
            text ""


errorFlash : FrameControls msg -> Maybe Session.Flash -> Html msg
errorFlash controls maybeFlash =
    let
        row ( heading, message ) =
            tr []
                [ th [] [ text (heading ++ ":") ]
                , td [] [ pre [] [ text message ] ]
                ]
    in
    case maybeFlash of
        Nothing ->
            text ""

        Just flash ->
            div [ class "well well-error" ]
                [ div [ class "flash-header" ]
                    [ h2 [] [ text flash.title ]
                    , a [ href "#", Events.onClick controls.clearFlash ] [ text "Close" ]
                    ]
                , div [ class "flash-table" ] (List.map row flash.table)
                ]


externalLink : String -> String -> Html a
externalLink url title =
    a [ href url, target "_blank", rel "noopener" ] [ text title ]


navbarLink : Page -> Route -> List (Html a) -> Page -> Html a
navbarLink page route linkContent activePage =
    li [ classList [ ( "navbar-active", page == activePage ) ] ]
        [ a [ class "navbar-active-bg", Route.href route ] linkContent ]


{-| Renders list of recent mailboxes, selecting the currently active mailbox.
-}
navbarRecent : Page -> FrameControls msg -> Html msg
navbarRecent page controls =
    let
        active =
            page == Mailbox

        -- Recent tab title is the name of the current mailbox when active.
        title =
            if active then
                controls.recentActive

            else
                "Recent Mailboxes"

        -- Mailboxes to show in recent list, doesn't include active mailbox.
        recentMailboxes =
            if active then
                List.tail controls.recentOptions |> Maybe.withDefault []

            else
                controls.recentOptions

        recentLink mailbox =
            a [ Route.href (Route.Mailbox mailbox) ] [ text mailbox ]
    in
    li
        [ class "navbar-recent"
        , classList [ ( "navbar-dropdown", True ), ( "navbar-active", active ) ]
        ]
        [ span [ class "navbar-active-bg" ] [ text title ]
        , div [ class "navbar-dropdown-content" ] (List.map recentLink recentMailboxes)
        ]