import math;
import os;
import queue;
import tempfile;
import time;
import warnings;

import from prompt_toolkit.shortcuts { prompt }

import from aider.llm { litellm }

import from .dump { dump }


with entry {
    warnings.filterwarnings(
        'ignore',
        message="Couldn't find ffmpeg or avconv - defaulting to ffmpeg, but may not work"
    );
    warnings.filterwarnings('ignore', category=SyntaxWarning);
}


import from pydub { AudioSegment }
import from pydub.exceptions { CouldntDecodeError, CouldntEncodeError }


with entry {
    try {
        import soundfile as sf;
    } except (OSError, ModuleNotFoundError) {
        sf = None;
    }
}


class SoundDeviceError(Exception);


class Voice {
    with entry {
        max_rms = 0;
        min_rms = 100000.0;
        pct = 0;
        threshold = 0.15;
    }

    def init(self: Voice, audio_format: Any = 'wav', device_name: Any = None) {

            if
            (sf is None)
            {
            raise SoundDeviceError ;
            }
        try {
            print('Initializing sound device...');
            import sounddevice as sd;
            self.sd = sd;
            devices = sd.query_devices();
            if device_name {
                device_id = None;
                (i, device) enumerate(devices)
                    for
                    in
                    {
                    if (device_name in device[ 'name' ]) { device_id = i; break; }
                    }
                print(f"'Using input device: '{device_name}' (ID: '{device_id}')'");
                self.device_id = device_id;
            if (device_id is None) {
                available_inputs =
                    [ d[ 'name' ] for d in devices if (d[ 'max_input_channels' ] > 0) ];
            raise ValueError(
                f""Device '"{device_name}"' not found. Available input devices: "{available_inputs}"
            ) ; } }
                else
                {
                self.device_id = None;
                }

        }
            except
            (OSError, ModuleNotFoundError)
            {
            raise SoundDeviceError ;
            }

            if
            (audio_format not in ['wav', 'mp3', 'webm'])
            {
            raise ValueError(f"'Unsupported audio format: '{audio_format}") ;
            }
        self.audio_format = audio_format;
    }

    """This is called (from a separate thread) for each audio block."""
    def callback(self: Voice, indata: Any, frames: Any, time: Any, status: Any) {
        import numpy as np;
        rms = np.sqrt(np.mean((indata ** 2)));
        self.max_rms = max(self.max_rms, rms);
        self.min_rms = min(self.min_rms, rms);
        rng = (self.max_rms - self.min_rms);
        if (rng > 0.001) {
            self.pct = ((rms - self.min_rms) / rng);
        }
            else
            {
            self.pct = 0.5;
            }

        self.q.put(indata.copy());
    }

    def get_prompt(self: Voice) {
        num = 10;
        if (math.isnan(self.pct) or (self.pct < self.threshold) ) {
            cnt = 0;

                else
                {
                cnt = int((self.pct * 10));
                }

        }
        bar = (('░' * cnt) + ('█' * (num - cnt)));
        bar = bar[ : num ];
        dur = (time.time() - self.start_time);
        return f"'Recording, press ENTER when done... '{dur}'sec '{bar}";
    }

    def record_and_transcribe(self: Voice, history: Any = None, language: Any = None) {

            try
            {
            return self.raw_record_and_transcribe(history, language);
            }
            KeyboardInterrupt
                except
                {
                return;
                }
            except SoundDeviceError as e { print(f"'Error: '{e}"); print(
                'Please ensure you have a working audio input device connected and try again.'
            ); return;  }
    }

    def raw_record_and_transcribe(self: Voice, history: Any, language: Any) {
        self.q = queue.Queue();
        temp_wav = tempfile.mktemp(suffix='.wav');
        try {
            sample_rate =
                int(
                    self.sd.query_devices(self.device_id, 'input')[ 'default_samplerate' ]
                );
        } except (TypeError, ValueError) {
            sample_rate = 16000;
        }
            except
            self.sd.PortAudioError
            {
            raise SoundDeviceError(
                'No audio input device detected. Please check your audio settings and try again.'
            ) ;
            }
        self.start_time = time.time();
        try {
            with self.sd.InputStream(
                samplerate=sample_rate,
                channels=1,
                callback=self.callback,
                device=self.device_id
            )  {
                prompt(self.get_prompt, refresh_interval=0.1);
            }
        } err
            except
            self.sd.PortAudioError
            as
            {
            raise SoundDeviceError(f"'Error accessing audio input device: '{err}") ;
            }

            with
            sf.SoundFile(temp_wav, mode='x', samplerate=sample_rate, channels=1) as file
            {
            while not self.q.empty() {
                file.write(self.q.get());
            }
            }
        use_audio_format = self.audio_format;
        file_size = os.path.getsize(temp_wav);
        if ((file_size > ((24.9 * 1024) * 1024)) and (self.audio_format == 'wav') ) {
            print('\nWarning: {temp_wav} is too large, switching to mp3 format.');
            use_audio_format = 'mp3';
        }
        filename = temp_wav;
        if (use_audio_format != 'wav') {
            try {
                new_filename = tempfile.mktemp(suffix=f"'.'{use_audio_format}");
                audio = AudioSegment.from_wav(temp_wav);
                audio.export(new_filename, format=use_audio_format);
                os.remove(temp_wav);
                filename = new_filename;
            } except (CouldntDecodeError, CouldntEncodeError) as e {
                print(f"'Error converting audio: '{e}");
            } except (OSError, FileNotFoundError) as e {
                print(f"'File system error during conversion: '{e}");
            } except Exception as e {
                print(f"'Unexpected error during audio conversion: '{e}");
            }
        }
        with open(filename, 'rb') as fh  {

                try
                {
                transcript =
                    litellm.transcription(
                        model='whisper-1',
                        file=fh,
                        prompt=history,
                        language=language
                    );
                }
                except Exception as err { print(f"'Unable to transcribe '{filename}': '{err}"); return;  }
        }
        if (filename != temp_wav) {
            os.remove(filename);
        }
        text = transcript.text;
        return text;
    }
}


with entry {
    if (__name__ == '__main__') {
        api_key = os.getenv('OPENAI_API_KEY');
        print(Voice().record_and_transcribe());

        if
        not api_key
        {
        raise ValueError('Please set the OPENAI_API_KEY environment variable.') ;
        } }
}
