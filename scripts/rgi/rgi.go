package main

import (
	"os/exec"
	"strings"
	"unicode/utf8"

	"github.com/gdamore/tcell/v2"
	"github.com/leaanthony/go-ansi-parser"
)

func main() {
	var err error
	rg, err = exec.LookPath("rg")
	check(err)

	screen, err := tcell.NewScreen()
	check(err)
	check(screen.Init())
	defer screen.Fini()

	search := ""

	for {
		render(search, screen)
		ev := screen.PollEvent()
		if ev, ok := ev.(*tcell.EventKey); ok {
			switch ev.Key() {
			case tcell.KeyCtrlC, tcell.KeyEscape:
				return
			case tcell.KeyBackspace, tcell.KeyDEL:
				j := 0
				for i := range search {
					j = i
				}
				search = search[:j]
			case tcell.KeyRune:
				search += string(ev.Rune())
			}
		}
	}
}

func render(search string, screen tcell.Screen) {
	screen.Clear()
	show(0, 0, screen, search)
	screen.ShowCursor(utf8.RuneCountInString(search), 0)
	check(ripgrep(search, screen))
	screen.Show()
}

var rg string

func ripgrep(search string, screen tcell.Screen) error {
	b, err := exec.Command(rg, "--heading", "--line-number", "--color", "always", search).CombinedOutput()
	if err != nil {
		if err, ok := err.(*exec.ExitError); ok {
			if err.ExitCode() == 1 {
				show(0, 2, screen, "<no match found>")
				return nil
			}
		} else {
			return err
		}
	}
	lines := strings.Split(string(b), "\n")
	_, height := screen.Size()
	for i := 0; i+2 < height && i < len(lines); i++ {
		showColor(0, i+2, screen, lines[i])
	}
	return nil
}

func showColor(x, y int, screen tcell.Screen, s string) {
	styled, err := ansi.Parse(s)
	if err != nil {
		cleansed, err := ansi.Cleanse(s)
		if err != nil {
			cleansed = s
		}
		show(x, y, screen, cleansed)
		return
	}

	for _, text := range styled {
		style := tcell.StyleDefault.
			Foreground(mapColor(text.FgCol)).
			Background(mapColor(text.BgCol)).
			Attributes(remap(text.Style))
		showStyled(x, y, screen, text.Label, style)
		x += utf8.RuneCountInString(text.Label)
	}
}

func mapColor(x *ansi.Col) tcell.Color {
	if x == nil {
		return tcell.ColorDefault
	}
	return tcell.GetColor(strings.ToLower(x.Name))
}

func remap(x ansi.TextStyle) tcell.AttrMask {
	return indicator(x&ansi.Bold)&tcell.AttrBold |
		indicator(x&ansi.Faint)&tcell.AttrDim |
		indicator(x&ansi.Italic)&tcell.AttrItalic |
		indicator(x&ansi.Blinking)&tcell.AttrBlink |
		indicator(x&ansi.Underlined)&tcell.AttrUnderline |
		indicator(x&ansi.Strikethrough)&tcell.AttrStrikeThrough
}

func indicator(i ansi.TextStyle) tcell.AttrMask {
	if i == 0 {
		return 0
	}
	return -1
}

func show(x, y int, screen tcell.Screen, s string) {
	showStyled(x, y, screen, s, tcell.StyleDefault)
}

func showStyled(x, y int, screen tcell.Screen, s string, style tcell.Style) {
	for _, c := range s {
		screen.SetContent(x, y, c, nil, style)
		x++
	}
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}
