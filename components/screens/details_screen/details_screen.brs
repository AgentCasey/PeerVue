' SPDX-FileCopyrightText: 2020 Tod Fitch <tod@fitchfamily.org>
'
' SPDX-License-Identifier: MIT

sub init()
    m.category          = m.top.FindNode("category")
    m.description       = m.top.FindNode("description")
    m.duration          = m.top.FindNode("duration")
    m.play_button       = m.top.FindNode("play_button")
    m.publishdate       = m.top.FindNode("publishdate")
    m.related_button    = m.top.FindNode("related_button")
    m.tags              = m.top.FindNode("tags")
    m.thumbnail         = m.top.FindNode("thumbnail")
    m.title             = m.top.FindNode("title")
    m.owner             = m.top.FindNode("owner")

    m.contentStack = []
    m.currentContent = invalid

    m.top.observeField("visible", "onVisibleChange")
    m.play_button.setFocus(true)
end sub

function onKeyEvent(key, press) as Boolean
    handled = false

    if (press)
        ? "[server_select] onKeyEvent", key, press
        if (key="up" or key="down") and m.play_button.hasFocus()
            m.related_button.setFocus(true)
            m.play_button.setFocus(false)
            handled = true
        else if (key="up" or key="down") and m.related_button.hasFocus()
            m.related_button.setFocus(false)
            m.play_button.setFocus(true)
            handled = true
        end if
        if (key="right" or key="left")
            if (m.description.hasFocus())
                m.description.setFocus(false)
                m.play_button.setFocus(true)
                m.related_button.setFocus(false)
            else
                m.description.setFocus(true)
                m.play_button.setFocus(false)
                m.related_button.setFocus(false)
            end if
            handled = true
        end if
    end if
    return handled
end function

function resetStack()
    m.contentStack = []
end function

function pushContent()
    m.contentStack.Push(m.currentContent)
end function

function popContent()
    contentInfo = m.contentStack.Pop()
    if (contentInfo <> invalid)
        setContent(contentInfo)
    end if
end function

sub onVisibleChange()
    if m.top.visible = true then
        m.play_button.setFocus(true)
    end if
end sub

sub OnContentChange(obj)
    item = obj.getData()
    setContent(item)
end sub

sub setContent(item)
    m.currentContent = item

    '? "details_screen :";item
    if item.name <> Invalid then
        m.title.text = item.name
    else
        m.title.text = ""
    end if

    '
    ' remove markdown hyperlinks of the form
    '
    ' [some text](url)
    '
    if item.description <> Invalid then
        regex1 = createObject("roRegEx", "\([A-Za-z]+:\/\/[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_:%&;\?\#\/.=]+\)", "gi")
        regex2 = createObject("roRegEx", "[\[\]]", "gi")
        text = regex1.ReplaceAll(item.description,"")
        m.description.text = regex2.ReplaceAll(text,"")
    else
        m.description.text = ""
    end if

    m.thumbnail.uri = get_setting("server", "") + item.thumbnailPath

    '
    '   Show duration as h:mm:ss
    '
    '   Seems like there should be a built-in function for formatting
    '   seconds to a string but I don't see it so we do it the hard way
    '
    sec = item.duration
    hr = (sec / 3600).ToStr().ToInt()
    sec = sec - (hr * 3600)
    min = (sec / 60).ToStr().ToInt()
    sec = sec - (min * 60)

    if (min > 9)
        min = min.toStr()
    else
        min = "0" + min.toStr()
    end if
    if (sec > 9)
        sec = sec.toStr()
    else
        sec = "0" + sec.toStr()
    end if
    m.duration.text = hr.toStr() + ":" + min + ":" + sec

    '
    '   Show video category
    '
    m.category.text = item.category.label

    '
    '   Show video tags
    '
    tagString = ""
    for each t in item.tags
        if (tagString <> "")
            tagString = tagString + ", "
        end if
        tagString = tagString + t
    end for
    m.tags.text = tagString
    m.top.related_tags = item.tags

    '
    '   Show publish date.
    '
    date = CreateObject("roDateTime")
    if (item.originallyPublishedAt <> invalid)
        date.FromISO8601String(item.originallyPublishedAt)
    else
        date.FromISO8601String(item.publishedAt)
    end if
    m.publishdate.text = date.AsDateString("short-month-no-weekday")

    '
    ' Show owener
    '
    m.top.video_owner = item.account.name + "@" + item.account.host
    m.owner.text = m.top.video_owner
end sub
