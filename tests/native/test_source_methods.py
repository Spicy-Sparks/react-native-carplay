from pathlib import Path
import unittest

from source_methods import extract_method


class SourceMethodTests(unittest.TestCase):
    def test_skips_prototypes_and_keeps_nested_method_body(self):
        signature = '- (void)cancelRequestsForTemplate:'
        source = '''@interface Example ()
- (void)cancelRequestsForTemplate:(NSString *)templateId;
@end
@implementation Example {
    BOOL active;
}
- (void)cancelRequestsForTemplate:(NSString *)templateId {
    if (templateId) { completion(@{}); }
}
- (void)unrelated { }
@end'''
        method = extract_method(source, signature)
        self.assertTrue(method.startswith(signature))
        self.assertIn('if (templateId) { completion(@{}); }', method)
        self.assertNotIn('@implementation', method)
        self.assertNotIn('unrelated', method)

    def test_extracts_current_production_cleanup_definitions(self):
        source = (Path(__file__).resolve().parents[2] / 'ios/RNCarPlay.m').read_text()
        for signature in ['- (void)cancelRequestsForTemplate:', '- (void)removeSearchTemplate:']:
            method = extract_method(source, signature)
            self.assertNotIn('@implementation RNCarPlay', method)
            self.assertIn('templateId {', method)

    def test_reports_a_prototype_without_an_implementation(self):
        with self.assertRaisesRegex(ValueError, 'No method implementation'):
            extract_method('- (void)missing;', '- (void)missing')


if __name__ == '__main__':
    unittest.main()
