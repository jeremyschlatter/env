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

	var (
		search []rune
		cursor int
	)

	for {
		{
			screen.Clear()

			show(0, 0, screen, string(search))
			screen.ShowCursor(cursor, 0)

			result, err := ripgrep(string(search), screen)
			check(err)

			lines := strings.Split(result, "\n")
			_, height := screen.Size()
			for i := 0; i+2 < height && i < len(lines); i++ {
				showColor(0, i+2, screen, lines[i])
			}

			screen.Show()
		}
		ev := screen.PollEvent()
		if ev, ok := ev.(*tcell.EventKey); ok {
			switch ev.Key() {
			case tcell.KeyCtrlC, tcell.KeyEscape:
				return
			case tcell.KeyBackspace, tcell.KeyDEL:
				if len(search) == 0 {
					continue
				}
				cursor--
				if len(search) <= cursor {
					search = search[:cursor]
				} else {
					search = append(search[:cursor], search[cursor+1:]...)
				}
			case tcell.KeyLeft:
				if cursor > 0 {
					cursor--
				}
			case tcell.KeyRight:
				if cursor < len(search) {
					cursor++
				}
			case tcell.KeyRune:
				search = append(search[:cursor], append([]rune{' '}, search[cursor:]...)...)
				search[cursor] = ev.Rune()
				cursor++
			}
		}
	}
}

var (
	rg         string
	prevSearch = "this initializer should be non-empty"
	prevResult string
)

func ripgrep(search string, screen tcell.Screen) (result string, err error) {
	if search == prevSearch {
		return prevResult, nil
	}
	defer func() {
		prevSearch = search
		prevResult = result
	}()
	b, err := exec.Command(rg, "--heading", "--line-number", "--color", "always", search).CombinedOutput()
	if exitErr, ok := err.(*exec.ExitError); ok {
		err = nil
		if exitErr.ExitCode() == 1 {
			b = []byte("<no match>")
		}
	}
	if err != nil {
		return "", err
	}
	return string(b), nil
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
	for i, c := range s {
		screen.SetContent(x+i, y, c, nil, style)
	}
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}
