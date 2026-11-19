package main

import (
	"context"
	"math"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"
)

var (
	audioToolsOnce   sync.Once
	audioFfmpegPath  string
	audioFfprobePath string
)

func GetAudioInfo(filePath string) (uint32, []byte) {
	audioToolsOnce.Do(func() {
		audioFfmpegPath, _ = exec.LookPath("ffmpeg")
		audioFfprobePath, _ = exec.LookPath("ffprobe")
	})

	const toolTimeout = 5 * time.Second
	var seconds uint32 = 0
	if len(audioFfprobePath) > 0 {
		ctx, cancel := context.WithTimeout(context.Background(), toolTimeout)
		out, err := exec.CommandContext(ctx, audioFfprobePath, "-v", "error",
			"-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1",
			filePath).Output()
		cancel()
		if err == nil {
			if duration, durErr := strconv.ParseFloat(strings.TrimSpace(string(out)), 64); (durErr == nil) && (duration > 0) {
				seconds = uint32(math.Max(1, math.Round(duration)))
			}
		}
	}

	var waveform []byte
	if len(audioFfmpegPath) > 0 {
		ctx, cancel := context.WithTimeout(context.Background(), toolTimeout)
		pcm, err := exec.CommandContext(ctx, audioFfmpegPath, "-nostdin", "-v", "error", "-i", filePath,
			"-ac", "1", "-ar", "200", "-f", "s16le", "-").Output()
		cancel()
		sampleCount := len(pcm) / 2
		if (err == nil) && (sampleCount > 0) {
			if seconds == 0 {
				seconds = uint32(math.Max(1, math.Round(float64(sampleCount)/200.0)))
			}
			const numBars = 64
			peaks := make([]int, numBars)
			maxPeak := 1
			for b := 0; b < numBars; b++ {
				s0 := (b * sampleCount) / numBars
				s1 := ((b + 1) * sampleCount) / numBars
				if s1 <= s0 {
					s1 = s0 + 1
				}
				peak := 0
				for i := s0; (i < s1) && (i < sampleCount); i++ {
					val := int(int16(uint16(pcm[2*i]) | (uint16(pcm[2*i+1]) << 8)))
					if val < 0 {
						val = -val
					}
					if val > peak {
						peak = val
					}
				}
				peaks[b] = peak
				if peak > maxPeak {
					maxPeak = peak
				}
			}
			waveform = make([]byte, numBars)
			for b := 0; b < numBars; b++ {
				waveform[b] = byte((peaks[b] * 100) / maxPeak)
			}
		}
	}

	return seconds, waveform
}
